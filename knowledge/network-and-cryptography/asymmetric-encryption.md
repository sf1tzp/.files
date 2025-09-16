# Asymmetric Encryption

Asymmetric encryption utilizes a "key pair" to encrypt data in _one direction_.

When a key pair is created,
- Public Key: Used to encrypt data or verify a digital signature.
- Private Key: Used to decrypt data or create a digital signature.

Asymmetric encryption algorithms are based on mathematical problems that are easy to perform in one direction but extremely difficult to reverse without a special number (the private key).  Commonly used systems rely on concepts like prime factorization or modular arithmetic.  The mathematics are more complex than symmetric algorithms.

## Practical Uses

### Confidentiality (Sending a Secret Message):
If Alice wants to send Bob a secret message, she uses Bob's public key to encrypt the message. Only Bob, possessing the corresponding private key, can decrypt it.

-   **Easy Key Distribution**  The public key is designed to be shared widely. Alice encrypts her message using the public key.
-   **Key Relationships:**  The *private* key is mathematically linked to the public key. The mathematical relationship between the keys means it's computationally infeasible to derive the private key from the public key.
Only the private key can decrypt a message encrypted by the pulic key.
-   **Key takeaway:**  Public key encryption guarantees *confidentiality* – only the intended recipient can read the message.

### Authentication & Integrity (Sign a message to prove it hasn't been altered):
-   **What is signing?**  Signing involves creating a cryptographic hash (a unique "fingerprint") of the message.  Then, Bob encrypts this hash using his *private* key. This encrypted hash is the digital signature.
-   **Verification:**  Alice (or anyone) uses Bob's *public* key to *decrypt* the digital signature.  This recovers the original hash value.  Independently, Alice calculates the hash of the message she received.  If the two hash values match, it proves two things:
    - **Authentication:** Bob wrote the message (because only Bob possesses the private key that could have created the signature).
    - **Integrity:** The message hasn't been altered since Bob signed it. Any change to the message would result in a different hash value, and the verification would fail.
    - **Non-Repudiation:** Prevents Bob from denying they sent a message, as only their private key could have created the signature.


## Eliptic Curve vs RSA

ECC provides equivalent security strength to RSA with significantly smaller key sizes, making it efficient for resource-constrained environments and mobile applications.

ECDSA (Elliptic Curve Digital Signature Algorithm) provides digital signatures using elliptic curve mathematics, offering efficiency benefits similar to ECC encryption.
