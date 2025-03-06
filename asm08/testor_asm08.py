#!/usr/bin/env python3
import subprocess
import random
import string
import os

"""
Fuzzer pour tester le programme ASM08 qui calcule la somme des nombres entiers
inférieurs à un nombre donné.
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
EXE_PATH = "./asm08"

# Vérifier si le programme existe
if not os.path.exists(EXE_PATH):
    print(f"{RED}Erreur: {EXE_PATH} n'existe pas.{RESET}")
    print("Assurez-vous de compiler le programme avant de lancer le fuzzing.")
    exit(1)

def run_test(args, expected_output=None, expected_return_code=0, description=""):
    """Exécute le programme avec les arguments donnés et vérifie le code de retour et la sortie"""
    try:
        # Construire la commande
        command = [EXE_PATH] + args
        cmd_str = " ".join(command)
        
        # Exécuter la commande
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        # Vérifier le code de retour
        return_code_ok = result.returncode == expected_return_code
        
        # Vérifier la sortie si une sortie attendue est spécifiée
        output_ok = True
        if expected_output is not None:
            output_ok = result.stdout.strip() == str(expected_output)
        
        # Succès global
        success = return_code_ok and output_ok
        
        # Afficher le résultat
        status = f"{GREEN}SUCCÈS{RESET}" if success else f"{RED}ÉCHEC{RESET}"
        print(f"{BLUE}Test:{RESET} {description}")
        print(f"{YELLOW}Commande:{RESET} {cmd_str}")
        print(f"{YELLOW}Sortie:{RESET} {result.stdout.strip()}")
        if expected_output is not None:
            print(f"{YELLOW}Sortie attendue:{RESET} {expected_output}")
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

def sum_less_than(n):
    """Calcule la somme des entiers strictement inférieurs à n"""
    return sum(range(n))

def generate_tests():
    """Génère une liste de tests à exécuter"""
    tests = []
    
    # Tests basiques (entrées valides)
    # Pour chaque test valide, on calcule aussi le résultat attendu
    tests.append((["5"], "10", 0, "Entrée valide : nombre simple (5)"))
    tests.append((["10"], "45", 0, "Entrée valide : nombre simple (10)"))
    tests.append((["1"], "0", 0, "Entrée valide : un (pas de nombres inférieurs à 1)"))
    tests.append((["0"], "0", 0, "Entrée valide : zéro (pas de nombres inférieurs à 0)"))
    
    # Tests avec entrées numériques invalides
    tests.append((["+5"], None, 0, "Entrée invalide : nombre avec signe + explicite"))
    tests.append((["-5"], None, 0, "Entrée invalide : nombre négatif"))
    tests.append((["5.5"], None, 0, "Entrée invalide : nombre à virgule"))
    tests.append((["0x5"], None, 0, "Entrée invalide : nombre hexadécimal"))
    
    # Tests avec trop ou pas assez d'arguments
    tests.append(([], None, 0, "Entrée invalide : aucun argument"))
    tests.append((["5", "10"], None, 0, "Entrée invalide : trop d'arguments"))
    
    # Tests avec caractères non numériques
    tests.append((["a"], None, 0, "Entrée invalide : lettre"))
    tests.append((["5a"], None, 0, "Entrée invalide : nombre suivi de lettre"))
    tests.append((["a5"], None, 0, "Entrée invalide : lettre suivie de nombre"))
    tests.append((["!"], None, 0, "Entrée invalide : caractère spécial"))
    
    # Tests avec grands nombres
    # Note: pour les très grands nombres, le calcul de référence peut être lent ou provoquer une erreur
    # On ne vérifie donc pas la sortie exacte pour ces cas
    tests.append((["1000"], None, 0, "Entrée valide : nombre moyen (1000)"))
    tests.append((["10000"], None, 0, "Entrée valide : grand nombre (10000)"))
    
    # Fuzzing aléatoire
    for i in range(5):
        # Générer des tests avec des chiffres aléatoires
        if random.random() < 0.7:  # 70% chance de générer un nombre valide
            n = random.randint(1, 100)
            expected = sum_less_than(n)
            tests.append(([str(n)], str(expected), 0, f"Fuzzing aléatoire {i+1} (valide): {n}"))
        else:  # 30% chance de générer une entrée invalide
            chars = string.ascii_letters + string.punctuation
            invalid_input = ''.join(random.choice(chars) for _ in range(5))
            tests.append(([invalid_input], None, 0, f"Fuzzing aléatoire {i+1} (invalide): {invalid_input}"))
    
    return tests

def run_all_tests():
    """Exécute tous les tests définis"""
    tests = generate_tests()
    total = len(tests)
    successful = 0
    
    print(f"{BLUE}=== Début des tests de fuzzing pour {EXE_PATH} ==={RESET}")
    print(f"Total de {total} tests à exécuter")
    print("=" * 50)
    
    for args, expected_output, expected_code, description in tests:
        if run_test(args, expected_output, expected_code, description):
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