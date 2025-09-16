# Symmetric Encryption Techniques

Symmetric encryption (secret-key encryption) uses a single shared key for both encryption and decryption. The security of the scheme depends entirely on the confidentiality of this key.

Users can either be given "pre shared keys", or they can mutually agree on a new key to use in a process known as "Key Exchange"


-   **Plaintext**: Original data in readable form
-   **Ciphertext**: Encrypted, unreadable data
-   **Key**: Secret bitstring used for encryption/decryption


3. Common Symmetric Encryption Algorithms:

-   **AES**: NIST standard (128/192/256-bit keys), widely recommended for new implementations
-   **DES**: Deprecated (56-bit key), vulnerable to brute-force attacks
-   **3DES**: Triple DES encryption (3x 56-bit keys), legacy use only
-   **ChaCha20**: Stream cipher with strong performance on software platforms, often paired with Poly1305 for authentication


4. Strengths:

-   High performance due to efficient block cipher design
-   Low computational overhead
-   Well-established cryptographic standards


5. Weaknesses:

-   Key distribution challenge (requires secure channel for key exchange)
-   Key compromise risk (all data encrypted with compromised key is vulnerable)
-   Scalability limitations (O(n²) key management complexity)


6. Applications:
- Full-disk encryption (e.g., BitLocker, LUKS)
- Database encryption (AES-256-CBC commonly used)
- TLS/SSL record layer (AES-GCM for authenticated encryption)
- Wireless security (WPA3 uses AES-CCM)
- Secure messaging (Signal Protocol uses AES for session encryption)


7. Key Exchange Solutions:

Since secure key exchange is vital, here are some methods commonly used:

-   **Diffie-Hellman**: Public-key key exchange protocol enabling shared secret derivation over insecure channels
-   **KEMs**: Key encapsulation mechanisms using asymmetric cryptography (e.g., RSA-KEM, ECIES) for secure symmetric key transport
-   **Pre-shared keys**: Manual key distribution limited to small, trusted networks
