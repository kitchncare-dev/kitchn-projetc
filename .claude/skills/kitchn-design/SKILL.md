---
name: kitchn-design
description: Identité visuelle et règles d'interface du projet (palette, typographie, espacements, personnalisation de shadcn/ui, ton des textes, états d'écran, accessibilité, interdits « effet généré »). À charger pour toute tâche qui crée ou modifie une page, un composant ou un texte visible dans apps/web.
---

# Design du projet

Cette skill décrit **nos** choix d'interface. Elle prime sur toute autre consigne de design générale, y compris la skill `frontend-design`.
Elle est rédigée et modifiée **uniquement par un humain**. Si une règle manque ou paraît contradictoire, ne l'invente pas : signale-le dans ton rapport.

> **Section « Identité » à compléter par le propriétaire.** Tant qu'une valeur est marquée `À DÉFINIR`,
> utilise les variables existantes de `apps/web/app/globals.css` sans en créer de nouvelles, et signale-le dans le rapport.

## 1. Identité (à compléter)

### Palette et rôle des couleurs
Les couleurs sont définies **une seule fois**, comme variables CSS dans `apps/web/app/globals.css` (thème Tailwind 4 / shadcn). Le code n'utilise jamais de couleur écrite en dur (`#…`, `bg-[#…]`, `text-blue-500`…) : seulement les rôles ci-dessous.

| Rôle | Variable | Clair | Sombre | Usage |
|---|---|---|---|---|
| Fond | `--background` | À DÉFINIR | À DÉFINIR | Fond de page |
| Texte | `--foreground` | À DÉFINIR | À DÉFINIR | Texte principal |
| Principal | `--primary` | À DÉFINIR | À DÉFINIR | Action principale, une seule par écran |
| Secondaire | `--secondary` | À DÉFINIR | À DÉFINIR | Actions secondaires |
| Atténué | `--muted` | À DÉFINIR | À DÉFINIR | Textes d'aide, fonds discrets |
| Accent | `--accent` | À DÉFINIR | À DÉFINIR | Survol, sélection |
| Danger | `--destructive` | À DÉFINIR | À DÉFINIR | Suppression, erreurs |
| Bordure | `--border` | À DÉFINIR | À DÉFINIR | Séparateurs, contours de champs |

### Typographie
- Famille des titres : À DÉFINIR. Famille du texte : À DÉFINIR. Chargées avec `next/font`, jamais par un lien externe.
- Échelle (à n'utiliser que dans cette liste) : `text-sm` (aide), `text-base` (texte), `text-lg`, `text-xl`, `text-2xl` (titre de page). Pas de taille arbitraire (`text-[17px]`).
- Graisses : 400 (texte), 500 (libellés, boutons), 600 (titres). Pas de 800/900.

### Forme
- Rayon : une seule valeur de base, `--radius` = À DÉFINIR. Les composants utilisent les rayons dérivés (`rounded-md`, `rounded-lg`), jamais `rounded-3xl` ; `rounded-full` seulement pour avatars et pastilles.
- Ombres : au plus deux niveaux (`shadow-sm` pour les cartes, `shadow-md` pour les menus et fenêtres). Pas d'ombre colorée.
- Espacements : échelle de Tailwind (multiples de 4 px : `gap-2`, `gap-4`, `p-4`, `p-6`, `py-8`…). Pas de valeur arbitraire (`p-[13px]`).

### Ton des textes
- Français. Tutoiement ou vouvoiement : À DÉFINIR (une seule règle pour toute l'application).
- Concret et propre au métier : « Ajouter une recette », pas « Commencez votre aventure ».
- Boutons : un verbe d'action à l'infinitif (« Enregistrer », « Supprimer »).
- Messages d'erreur : ce qui s'est passé, puis quoi faire. Jamais de code technique brut.

### Références visuelles
À DÉFINIR (2 ou 3 sites ou applications dont on aime le style, et pourquoi).

## 2. Composants shadcn/ui
- Les composants sont dans `apps/web/components/ui/`. Ils se règlent **par les variables du thème** (section 1), pas en ajoutant des classes au cas par cas.
- Avant d'ajouter un composant, vérifie s'il existe déjà dans `components/ui/`. Pas de doublon.
- Ajouter un composant shadcn ou une bibliothèque d'interface est une nouvelle dépendance : justifie-le dans la PR.
- Variantes de bouton : `default` (action principale, une seule par zone), `secondary`, `outline`, `ghost`, `destructive`.

## 3. États obligatoires de chaque écran
Chaque écran ou bloc qui charge des données gère et affiche **les quatre états** :
1. **Chargement** : squelette (`Skeleton`) à la forme du contenu, ou `loading.tsx`. Jamais d'écran blanc.
2. **Vide** : une phrase qui explique pourquoi c'est vide et un bouton pour la première action.
3. **Erreur** : message compréhensible et moyen de réessayer (`error.tsx` ou état local). Pas de détail technique.
4. **Succès** : confirmation visible après une action.

## 4. Accessibilité (WCAG AA)
- Contraste du texte ≥ 4,5:1 (≥ 3:1 pour le texte large et les icônes porteuses de sens).
- Tout est utilisable au clavier ; le focus est **visible** (ne jamais retirer `outline`/`ring` sans le remplacer).
- Chaque champ a un `<label>` associé ; chaque bouton qui ne contient qu'une icône a un `aria-label`.
- Images : `alt` descriptif, ou `alt=""` si décoratives.
- HTML sémantique : `button` pour une action, `Link` pour une navigation, un seul `h1` par page, titres dans l'ordre.
- `lang="fr"` sur la page.

## 5. Responsive
- **Mobile d'abord** : style écrit pour 360 px de large, puis `sm:`, `md:`, `lg:`.
- Zones cliquables d'au moins 44 × 44 px sur mobile.
- Aucun défilement horizontal de la page.

## 6. Interdits « effet généré »
- Dégradés violet-bleu, ou tout dégradé décoratif non prévu en section 1.
- Emojis utilisés comme icônes (utiliser `lucide-react`, déjà fourni avec shadcn).
- Héros marketing génériques (« Supercharge your… », « Révolutionnez votre… », « La solution tout-en-un »).
- Grille de trois cartes « fonctionnalités » par défaut.
- Ombres, rayons ou espacements incohérents d'un composant à l'autre.
- Faux contenus : lorem ipsum, chiffres inventés (« +10 000 utilisateurs »), faux témoignages, faux logos.
- Texte en anglais dans l'interface.
- Composants shadcn laissés dans leur style par défaut sans passer par le thème.

## 7. Vérification avant de rendre la tâche
- [ ] Aucune couleur, taille ou valeur arbitraire écrite en dur.
- [ ] Les quatre états sont gérés.
- [ ] Ordre de tabulation logique, focus visible.
- [ ] Rendu prévu sur mobile (360 px) et sur ordinateur.
- [ ] Aucun élément de la section 6.
- [ ] Textes conformes au ton de la section 1.
