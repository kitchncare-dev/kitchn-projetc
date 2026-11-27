# Pont Telegram → GitHub

Petit service Cloud Run (projet **dev** uniquement) qui permet de piloter les agents depuis Telegram.

```
Toi (Telegram) ──► bot ──► telegram-bridge (Cloud Run) ──► issue GitHub ──► label ai-dev ──► agent-dev
      ▲                                                                                        │
      └────────────── notifications (workflows GitHub Actions → API Telegram) ◄─────────────────┘
```

## Utilisation

| Tu envoies au bot | Ce qui se passe |
|---|---|
| Un message texte | Une issue est créée **sans label** (1re ligne = titre, le reste = description). Le bot répond avec « 🚀 Lancer l'agent » et « Voir sur GitHub ». |
| Clic sur « 🚀 Lancer l'agent » | Le label `ai-dev` est posé : le workflow `agent-dev` démarre. |
| `/r 42 ta réponse` | Ta réponse est ajoutée en commentaire de l'issue #42, avec un bouton « 🔁 Relancer l'agent ». |
| Une **réponse** (glisser vers la gauche) à une notification qui contient `#42` | Même chose que `/r 42`. |
| `/aide` | Rappel des commandes. |

Tu reçois une notification au démarrage et à la fin de l'orchestrateur (PR, questions, échec, consommation), au verdict de la relecture IA, lors d'une republication (`agent-publish`) et à chaque déploiement en dev.

## Sécurité

- Seul **ton** identifiant Telegram est accepté ; les autres messages sont ignorés sans réponse.
- Telegram signe chaque appel avec un jeton secret (`telegram-webhook-secret`) : un appel sans ce jeton est refusé (403).
- Le jeton GitHub du bridge n'a que les droits **Issues** sur ce dépôt : il ne peut ni pousser du code ni fusionner.
- Les secrets sont dans **Secret Manager** (projet dev), jamais dans le dépôt ni dans l'état Terraform.
- Ce dossier est réservé aux humains : les agents n'ont pas le droit de le modifier.
- Un message devient une consigne pour les agents : le résultat peut arriver en dev, **jamais en prod sans ton approbation**.

## Mise en service (une seule fois)

Les commandes `gcloud` se lancent dans **Cloud Shell** (console Google Cloud, icône `>_` en haut à droite), projet `kitchn-dev-515310`.

### 1. Créer le bot
1. Dans Telegram, ouvre une conversation avec **@BotFather**, envoie `/newbot`, choisis un nom puis un identifiant finissant par `bot`.
2. BotFather te donne un **jeton** (`123456789:AA…`). Ne le colle nulle part sauf dans la commande de l'étape 4.

### 2. Créer le jeton GitHub du bridge
GitHub → photo de profil → **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token** :
- **Resource owner** : `kitchncare-dev` ; **Repository access** : *Only select repositories* → `kitchn-projetc` ;
- **Permissions → Repository** : **Issues : Read and write** (Metadata passe automatiquement en lecture). Rien d'autre ;
- **Expiration** : 1 an maximum (note la date pour le renouveler).

Si l'organisation exige une approbation des jetons, approuve-le dans les réglages de l'organisation.

### 3. Créer l'infrastructure (Terraform, à la main)
Dans Cloud Shell, depuis le dépôt à jour :
```bash
cd infra/envs/dev
terraform init
terraform plan
terraform apply
```
Le plan doit créer : le compte `sa-telegram-bridge`, 4 secrets, le service Cloud Run `telegram-bridge` (image provisoire) et le droit pour `sa-deploy-dev` de le déployer.

### 4. Enregistrer les secrets dans Secret Manager
```bash
read -s -p "Jeton du bot Telegram : " T && printf '%s' "$T" | gcloud secrets versions add telegram-bot-token --data-file=- && unset T; echo
read -s -p "Jeton GitHub (fine-grained) : " T && printf '%s' "$T" | gcloud secrets versions add telegram-bridge-github-token --data-file=- && unset T; echo
openssl rand -hex 32 | tr -d '\n' | gcloud secrets versions add telegram-webhook-secret --data-file=-
printf '0' | gcloud secrets versions add telegram-owner-id --data-file=-
```
`read -s` masque la saisie : le jeton n'apparaît ni à l'écran ni dans l'historique. L'identifiant du propriétaire vaut `0` pour l'instant (étape 6).

### 5. Déployer le bridge et brancher Telegram
1. GitHub → **Actions → deploy-bridge → Run workflow** (branche `dev`).
2. Dans Cloud Shell, déclare l'adresse du bridge à Telegram :
```bash
URL=$(gcloud run services describe telegram-bridge --region europe-west9 --format='value(status.url)')
TOKEN=$(gcloud secrets versions access latest --secret telegram-bot-token)
SECRET=$(gcloud secrets versions access latest --secret telegram-webhook-secret)
curl -s "https://api.telegram.org/bot${TOKEN}/setWebhook" \
  --data-urlencode "url=${URL}/webhook" \
  --data-urlencode "secret_token=${SECRET}" \
  --data-urlencode 'allowed_updates=["message","callback_query"]'
unset TOKEN SECRET
```
La réponse doit contenir `"ok":true`.

### 6. Déclarer ton identifiant Telegram
1. Envoie n'importe quel message à ton bot : il te répond « Ton identifiant Telegram est : 123456789 ».
2. Enregistre-le, puis relance **Actions → deploy-bridge → Run workflow** pour que le bridge le prenne en compte :
```bash
printf '123456789' | gcloud secrets versions add telegram-owner-id --data-file=-
```
À partir de là, le bot n'écoute plus que toi.

### 7. Activer les notifications
GitHub → **Settings → Secrets and variables → Actions → New repository secret** :
- `TELEGRAM_BOT_TOKEN` : le jeton du bot ;
- `TELEGRAM_CHAT_ID` : ton identifiant Telegram (étape 6).

Sans ces deux secrets, les workflows fonctionnent normalement, sans notification.

## Vérifier et dépanner

- Envoie `/aide` au bot : il doit répondre.
- Journaux : console Google Cloud → **Cloud Run → telegram-bridge → Journaux**.
- État du webhook (dernière erreur éventuelle de Telegram) :
```bash
TOKEN=$(gcloud secrets versions access latest --secret telegram-bot-token)
curl -s "https://api.telegram.org/bot${TOKEN}/getWebhookInfo"; unset TOKEN
```

## Développer

```bash
pip install -r ops/telegram-bridge/requirements.txt
python -m pytest ops/telegram-bridge -q
```
Le workflow `deploy-bridge` relance ces tests avant chaque déploiement (push sur `dev` qui touche ce dossier, ou lancement manuel).
