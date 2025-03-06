#!/usr/bin/env python3
import subprocess
import random
import string
import os

"""
Fuzzer pour tester le programme ASM09 de conversion de base numérique.
Ce script teste différentes entrées pour vérifier que le programme
respecte toutes les instructions données.
"""

# Couleurs pour l'affichage
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
RESET = "\033[0m"

# Chemin vers l'exécutable
EXE_PATH = "./asm09"

# Vérifier si le programme existe
if not os.path.exists(EXE_PATH):
    print(f"{RED}Erreur: {EXE_PATH} n'existe pas.{RESET}")
    print("Assurez-vous de compiler le programme avant de lancer le fuzzing.")
    exit(1)

def run_test(args, expected_return_code=0, description=""):
    """Exécute le programme avec les arguments donnés et vérifie le code de retour"""
    try:
        # Construire la commande
        command = [EXE_PATH] + args
        cmd_str = " ".join(command)
        
        # Exécuter la commande
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        # Vérifier le code de retour
        success = result.returncode == expected_return_code
        
        # Afficher le résultat
        status = f"{GREEN}SUCCÈS{RESET}" if success else f"{RED}ÉCHEC{RESET}"
        print(f"{BLUE}Test:{RESET} {description}")
        print(f"{YELLOW}Commande:{RESET} {cmd_str}")
        print(f"{YELLOW}Sortie:{RESET} {result.stdout.strip()}")
        if result.stderr:
            print(f"{YELLOW}Erreur:{RESET} {result.stderr.strip()}")
        print(f"{YELLOW}Code de retour:{RESET} {result.returncode} (attendu: {expected_return_code})")
        print(f"{YELLOW}Résultat:{RESET} {status}")
        print("-" * 50)
        
        return success
    except Exception as e:
        print(f"{RED}Erreur lors de l'exécution:{RESET} {e}")
        print("-" * 50)
        return False

def generate_tests():
    """Génère une liste de tests à exécuter"""
    tests = []
    
    # Test basiques (entrées valides)
    tests.append((["15"], 0, "Entrée valide : nombre décimal simple"))
    tests.append((["-b", "15"], 0, "Entrée valide : mode binaire"))
    tests.append((["42"], 0, "Entrée valide : autre nombre"))
    tests.append((["0"], 0, "Entrée valide : zéro"))
    
    # Test avec arguments invalides
    tests.append(([], 0, "Entrée invalide : aucun argument"))
    tests.append((["a"], 0, "Entrée invalide : caractère non numérique"))
    tests.append((["15", "42"], 0, "Entrée invalide : trop d'arguments"))
    tests.append((["-x", "15"], 0, "Entrée invalide : option non supportée"))
    tests.append((["-b", "15", "extra"], 0, "Entrée invalide : trop d'arguments avec option"))
    
    # Test avec signes explicites (+ et -)
    tests.append((["+15"], 0, "Entrée invalide : nombre avec signe +"))
    tests.append((["-15"], 0, "Entrée invalide : nombre avec signe -"))
    tests.append((["-b", "+15"], 0, "Entrée invalide : nombre avec signe + en mode binaire"))
    
    # Test avec grands nombres
    tests.append((["1000000"], 0, "Entrée valide : grand nombre"))
    tests.append((["-b", "1000000"], 0, "Entrée valide : grand nombre en mode binaire"))
    
    # Test avec caractères spéciaux mélangés
    tests.append((["15abc"], 0, "Entrée invalide : nombre suivi de lettres"))
    tests.append((["15\n"], 0, "Entrée invalide : nombre suivi de retour à la ligne"))
    
    # Test avec formats hexadécimaux ou binaires (qui devraient être rejetés)
    tests.append((["0x15"], 0, "Entrée invalide : format hexadécimal"))
    tests.append((["0b1111"], 0, "Entrée invalide : format binaire"))
    
    # Fuzzing aléatoire
    for i in range(5):
        # Générer une chaîne aléatoire
        random_str = ''.join(random.choice(string.ascii_letters + string.digits + string.punctuation) for _ in range(10))
        tests.append(([random_str], 0, f"Fuzzing aléatoire {i+1}: {random_str}"))
    
    return tests

def run_all_tests():
    """Exécute tous les tests définis"""
    tests = generate_tests()
    total = len(tests)
    successful = 0
    
    print(f"{BLUE}=== Début des tests de fuzzing pour {EXE_PATH} ==={RESET}")
    print(f"Total de {total} tests à exécuter")
    print("=" * 50)
    
    for args, expected_code, description in tests:
        if run_test(args, expected_code, description):
            successful += 1
    
    # Afficher le résumé
    print(f"{BLUE}=== Résumé des tests ==={RESET}")
    print(f"Tests réussis: {successful}/{total} ({successful/total*100:.2f}%)")
    
    if successful == total:
        print(f"{GREEN}Tous les tests ont réussi!{RESET}")
    else:
        print(f"{RED}{total-successful} tests ont échoué.{RESET}")

if __name__ == "__main__":
    run_all_tests()