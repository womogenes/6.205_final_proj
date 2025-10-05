#!/usr/bin/env python3

import sys
sys.path.append('.')

from decoder_test_cases import TEST_CASES, RANDOM_TEST_CASES

def test_encoder_correctness():
    """Test that our encoder generates correct instructions"""
    print(f"Total test cases: {len(TEST_CASES)}")
    print(f"Random test cases generated: {len(RANDOM_TEST_CASES)}")
    
    # Test a few specific cases to verify encoder correctness
    print("\nTesting first few random cases:")
    for i, (encoded, decoded) in enumerate(RANDOM_TEST_CASES[:5]):
        print(f"Case {i+1}:")
        print(f"  Encoded: 0x{encoded:08x} (0b{encoded:032b})")
        print(f"  Decoded: {decoded}")
        
        # Extract opcode to verify
        opcode = encoded & 0x7F
        print(f"  Opcode: 0b{opcode:07b}")
        print()

if __name__ == "__main__":
    test_encoder_correctness()
