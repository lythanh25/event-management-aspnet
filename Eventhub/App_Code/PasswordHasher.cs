using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Web;

namespace Eventhub.App_Code
{
    /// <summary>
    /// Hash và xác thực mật khẩu bằng PBKDF2-SHA256.
    /// Định dạng lưu trong DB: "pbkdf2:{iterations}:{salt_base64}:{hash_base64}"
    /// </summary>
    public static class PasswordHasher
    {
        private const int Iterations = 100000;   // 100k vòng
        private const int SaltSize = 16;       // 16 bytes
        private const int HashSize = 32;       // 32 bytes (256-bit)

        public static string Hash(string password)
        {
            if (string.IsNullOrEmpty(password))
                throw new ArgumentException("Mật khẩu rỗng", "password");

            byte[] salt = new byte[SaltSize];
            using (var rng = RandomNumberGenerator.Create())
                rng.GetBytes(salt);

            byte[] hash;
            using (var pbkdf2 = new Rfc2898DeriveBytes(password, salt, Iterations, HashAlgorithmName.SHA256))
                hash = pbkdf2.GetBytes(HashSize);

            return string.Format("pbkdf2:{0}:{1}:{2}",
                Iterations,
                Convert.ToBase64String(salt),
                Convert.ToBase64String(hash));
        }

        public static bool Verify(string password, string stored)
        {
            if (string.IsNullOrEmpty(password) || string.IsNullOrEmpty(stored))
                return false;

            try
            {
                var parts = stored.Split(':');
                if (parts.Length != 4 || parts[0] != "pbkdf2") return false;

                int iterations = int.Parse(parts[1]);
                byte[] salt = Convert.FromBase64String(parts[2]);
                byte[] storedHash = Convert.FromBase64String(parts[3]);

                byte[] testHash;
                using (var pbkdf2 = new Rfc2898DeriveBytes(password, salt, iterations, HashAlgorithmName.SHA256))
                    testHash = pbkdf2.GetBytes(storedHash.Length);

                return SlowEquals(storedHash, testHash);
            }
            catch
            {
                return false;
            }
        }

        private static bool SlowEquals(byte[] a, byte[] b)
        {
            if (a.Length != b.Length) return false;
            int diff = 0;
            for (int i = 0; i < a.Length; i++)
                diff |= a[i] ^ b[i];
            return diff == 0;
        }
    }
}