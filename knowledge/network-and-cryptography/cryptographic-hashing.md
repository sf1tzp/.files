# Cryptographic Hashing

At its core, a hash function is a mathematical function that takes an input of any size (a file, a password, a message – anything!) and produces a fixed-size output, known as a hash, hash value, digest, or checksum. Think of it as a digital fingerprint.

Key Characteristics:

- Deterministic:  The same input always produces the same output.
-   Fixed Size Output: Regardless of the input's size, the hash output remains a predictable length (e.g., 256 bits for SHA-256).
-   One-Way Function: It's computationally infeasible to reverse the process - meaning, given a hash value, it's virtually impossible to determine the original input. This is the "one-way" property.
-   Avalanche Effect:  Even a tiny change in the input should result in a significantly different hash output.  This makes it very difficult to manipulate data without detection.


Common Hashing Algorithms:

-   MD5:  Deprecated due to vulnerabilities.  Avoid using it.
-   SHA-1:  Deprecated due to vulnerabilities. Avoid using it.
-   SHA-256: A widely used and secure hashing algorithm (part of the SHA-2 family).
-   SHA-384 & SHA-512:  Other secure hashing algorithms in the SHA-2 family, offering larger output sizes.
-   SHA-3 (Keccak): A newer hashing standard designed as an alternative to the SHA family.
-   BLAKE2: A fast and secure hashing algorithm.


2. Practical Uses of Hashing

Hashing has numerous applications in computer science and security:

-    Password Storage: Instead of storing passwords directly, websites store their hashes.  When a user tries to log in, the website hashes the entered password and compares it to the stored hash. This prevents attackers who gain access to the database from directly accessing passwords.
-   Data Integrity Verification: Hashing allows you to verify that a file hasn't been altered. You calculate the hash of a file and store it. Later, you recalculate the hash and compare it to the stored value. Any difference indicates data corruption or tampering.  This is common for software downloads.
-   Digital Signatures: Hashing is a crucial part of digital signatures.  A document is hashed, and the hash is encrypted using the signer’s private key.  This allows verification that the document hasn't been altered and confirms the signer's identity.
-   Data Structures: Hashing is used to implement hash tables, a highly efficient data structure for quick lookups.
-   Blockchain Technology: Cryptographic hashing is fundamental to blockchain technology, used for linking blocks and ensuring data integrity.


3. Hash Collisions: A Risk to Consider

A hash collision occurs when two different inputs produce the same hash output.

-   Why they happen: Because hash functions map a potentially infinite input space to a finite output space.  A "pigeonhole principle" guarantees that collisions must exist.
-   The problem: While collisions are inevitable, strong hashing algorithms are designed to make them extremely difficult to find intentionally.  A malicious actor might try to engineer a collision to:
    -   Forge a digital signature: Create a document with a different content but the same signature.
    -   Bypass authentication: Find a different input that hashes to the same value as a valid password.



4. Salting: Protecting Passwords

The risk of hash collisions is less of a problem for general data integrity checks, but for password storage,  a different vulnerability arises: rainbow table attacks.

-   Rainbow Tables: Precomputed tables containing common passwords and their corresponding hashes. Attackers can use these to quickly look up the password associated with a stolen hash.


Salting is the solution:

-   What is a Salt?  A random string of characters added to the password before hashing. This "salt" is unique to each user.
-   How it works: Instead of hashing "password123," the system hashes "salt1password123".  Even if two users have the same password, their salts are different, so their hashes will be different.
-   Benefits:
    -   Defeats Rainbow Tables:  Because each password is hashed with a unique salt, rainbow tables become useless.
    -   Increases Hash Complexity:  The salt effectively expands the input space, making it significantly harder to find collisions.

-   Important Considerations:
     -  Store the Salt:  The salt must be stored alongside the hash (typically in the same database record).
     -  Uniqueness:  Each user should have a unique salt.

