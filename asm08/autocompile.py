#!/bin/bash
# Script pour compiler automatiquement les fichiers ASM

# Vérifier s'il y a un argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <fichier.asm>"
    echo "Exemple: $0 asm01.asm"
    exit 1
fi

# Récupérer le fichier d'entrée
input_file=$1

# Vérifier si le fichier existe
if [ ! -f "$input_file" ]; then
    echo "Erreur: Le fichier $input_file n'existe pas."
    exit 1
fi

# Vérifier que le fichier est bien un .asm
if [[ $input_file != *.asm ]]; then
    echo "Erreur: Le fichier doit avoir l'extension .asm"
    exit 1
fi

# Extraire le nom de base (sans l'extension)
base_name=$(basename "$input_file" .asm)

# Afficher les informations
echo "Compilation de $input_file..."
echo "Nom de sortie: $base_name"

# Compiler avec nasm
echo "Étape 1: Assemblage avec nasm..."
nasm -f elf64 -o "${base_name}.o" "$input_file"

# Vérifier si l'assemblage a réussi
if [ $? -ne 0 ]; then
    echo "Erreur lors de l'assemblage avec nasm."
    exit 1
fi

# Lier avec ld
echo "Étape 2: Édition de liens avec ld..."
ld -o "${base_name}" "${base_name}.o"

# Vérifier si l'édition de liens a réussi
if [ $? -ne 0 ]; then
    echo "Erreur lors de l'édition de liens avec ld."
    exit 1
fi

# Nettoyer les fichiers intermédiaires (optionnel)
echo "Étape 3: Nettoyage des fichiers intermédiaires..."
rm "${base_name}.o"

# Définir les permissions d'exécution
chmod +x "${base_name}"

echo "Compilation terminée avec succès!"
echo "Exécutable créé: ${base_name}"

# Afficher comment exécuter le programme
echo ""
echo "Pour exécuter le programme, utilisez:"
echo "./${base_name}"
