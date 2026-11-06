// =====================================================================
// DarImmo - Edge Function "send-push" (tickets 1.7, 8.1, 8.2) - membre C
//
// Appelée par deux Database Webhooks Supabase :
//   - INSERT sur public.messages  -> notifie le destinataire du message
//   - UPDATE sur public.annonces  -> notifie l'annonceur si le statut change
//
// Secrets à définir (Dashboard > Edge Functions > Secrets) :
//   FCM_SERVICE_ACCOUNT : contenu complet du fichier JSON du compte de service Firebase
//   WEBHOOK_SECRET      : un mot de passe inventé, aussi mis dans l'en-tête des webhooks
// SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY sont fournis automatiquement.
// =====================================================================
import { createClient } from "npm:@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, // contourne RLS : lecture des jetons
);

type ServiceAccount = { project_id: string; client_email: string; private_key: string };
const serviceAccount: ServiceAccount = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT") ?? "{}");

// ---------------------------------------------------------------------
// Jeton d'accès Google (OAuth2, JWT signé RS256), mis en cache ~55 min
// ---------------------------------------------------------------------
let cachedToken: { value: string; expires: number } | null = null;

function base64url(bytes: Uint8Array): string {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expires > now + 60) return cachedToken.value;

  const enc = (o: unknown) => base64url(new TextEncoder().encode(JSON.stringify(o)));
  const unsigned = `${enc({ alg: "RS256", typ: "JWT" })}.${enc({
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  })}`;

  const pem = serviceAccount.private_key.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8", der, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned)),
  );

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${unsigned}.${base64url(signature)}`,
    }),
  });
  const json = await res.json();
  if (!res.ok) throw new Error(`OAuth Google : ${JSON.stringify(json)}`);
  cachedToken = { value: json.access_token, expires: now + json.expires_in };
  return cachedToken.value;
}

// ---------------------------------------------------------------------
// Envoi à tous les appareils d'un utilisateur
// ---------------------------------------------------------------------
async function sendToUser(userId: string, title: string, body: string, data: Record<string, string>) {
  const { data: tokens, error } = await supabase
    .from("device_tokens").select("token").eq("id_user", userId);
  if (error) throw error;
  if (!tokens?.length) return { sent: 0 };

  const accessToken = await getAccessToken();
  let sent = 0;
  for (const { token } of tokens) {
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
      {
        method: "POST",
        headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          message: { token, notification: { title, body }, data, android: { priority: "high" } },
        }),
      },
    );
    if (res.ok) {
      sent++;
    } else {
      const err = await res.text();
      console.error("FCM", res.status, err);
      // Jeton périmé (application désinstallée...) : on le supprime
      if (res.status === 404 || err.includes("UNREGISTERED")) {
        await supabase.from("device_tokens").delete().eq("token", token);
      }
    }
  }
  return { sent };
}

const STATUT_TEXTE: Record<string, [string, string]> = {
  publiee: ["Annonce publiée", "Votre annonce « %s » est en ligne."],
  rejetee: ["Annonce rejetée", "Votre annonce « %s » a été rejetée. Ouvrez l'application pour voir le motif."],
  masquee: ["Annonce masquée", "Votre annonce « %s » a été masquée suite à un signalement."],
};

// ---------------------------------------------------------------------
// Point d'entrée
// ---------------------------------------------------------------------
Deno.serve(async (req) => {
  if (req.headers.get("x-webhook-secret") !== Deno.env.get("WEBHOOK_SECRET")) {
    return new Response("Non autorisé", { status: 401 });
  }

  try {
    const payload = await req.json(); // { type, table, record, old_record }
    let result: unknown = { ignored: true };

    // ----- Nouveau message (8.1)
    if (payload.table === "messages" && payload.type === "INSERT") {
      const msg = payload.record;
      const { data: conv } = await supabase
        .from("conversations").select("id_acheteur, id_vendeur").eq("id", msg.id_conversation).single();
      const { data: sender } = await supabase
        .from("profiles").select("nom").eq("id", msg.id_expediteur).single();
      if (conv) {
        const recipient = conv.id_acheteur === msg.id_expediteur ? conv.id_vendeur : conv.id_acheteur;
        const text = msg.contenu.length > 100 ? msg.contenu.slice(0, 97) + "…" : msg.contenu;
        result = await sendToUser(recipient, `Nouveau message de ${sender?.nom || "un utilisateur"}`, text, {
          type: "message",
          id_conversation: msg.id_conversation,
        });
      }
    }

    // ----- Changement de statut d'une annonce (8.2)
    if (payload.table === "annonces" && payload.type === "UPDATE") {
      const { record: a, old_record: old } = payload;
      const texte = STATUT_TEXTE[a.statut];
      if (texte && a.statut !== old?.statut) {
        result = await sendToUser(a.id_annonceur, texte[0], texte[1].replace("%s", a.titre), {
          type: "statut",
          id_annonce: a.id,
          statut: a.statut,
        });
      }
    }

    return Response.json(result);
  } catch (e) {
    console.error(e);
    return Response.json({ error: String(e) }, { status: 500 });
  }
});
