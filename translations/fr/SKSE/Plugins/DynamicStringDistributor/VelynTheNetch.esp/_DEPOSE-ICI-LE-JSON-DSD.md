# Dépose ici le fichier DSD français produit par SSE-AT

Quand ta traduction française est prête dans **SSE-AT**, exporte-la au format **DSD**. SSE-AT génère un
fichier `.json`. **Copie ce `.json` dans CE dossier** (à côté de ce fichier), par exemple :

    VelynTheNetch_French.json

C'est tout — je récupérerai ce dossier tel quel pour l'option « Français » du FOMOD (il s'installera à
`Data\SKSE\Plugins\DynamicStringDistributor\VelynTheNetch.esp\` chez le joueur).

Tu peux supprimer ce fichier `.md` une fois le `.json` déposé (ou le laisser, il ne gêne pas).

---

## Rappel du workflow
1. **SSE-AT** lit les chaînes anglaises de `VelynTheNetch.esp` (menus, dialogues, livre, notifications).
2. Tu traduis en français (manuellement).
3. Export **DSD** → un `.json` → **à copier ici**.

Le menu **MCM** est traité à part (pas par DSD) : son fichier français
`Interface\Translations\VelynTheNetch_FRENCH.txt` existe déjà, je l'inclurai aussi dans l'option FR du
FOMOD. Tu n'as rien à faire pour le MCM.
