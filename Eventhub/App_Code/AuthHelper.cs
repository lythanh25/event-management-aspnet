using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.SessionState;

namespace Eventhub.App_Code
{
    public class UserAccount
    {
        public long Id { get; set; }
        public string EmployeeCode { get; set; }
        public string Email { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string DisplayName { get; set; }
        public long? DepartmentId { get; set; }
        public string DepartmentName { get; set; }
        public long RoleId { get; set; }
        public string RoleCode { get; set; }
        public string RoleName { get; set; }
        public bool IsActive { get; set; }

        public string FullName
        {
            get
            {
                return !string.IsNullOrWhiteSpace(DisplayName)
                    ? DisplayName
                    : (LastName + " " + FirstName).Trim();
            }
        }
    }

    /// <summary>
    /// Class helper xử lý đăng nhập / đăng ký / session — dùng SQL Server (ADO.NET).
    /// </summary>
    public static class AuthHelper
    {
        // ──────────── KHÓA SESSION ────────────
        public const string SESSION_USER_ID = "UserId";
        public const string SESSION_USER_EMAIL = "UserEmail";
        public const string SESSION_USER_NAME = "UserFullName";
        public const string SESSION_ROLE_CODE = "UserRoleCode";

        // ═════════════════════════════════════════════════════════
        // LOGIN
        // ═════════════════════════════════════════════════════════
        public static UserAccount FindUser(string email, string password)
        {
            if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
                return null;

            const string sql = @"
                SELECT TOP 1
                    u.id, u.employee_code, u.email, u.password_hash,
                    u.first_name, u.last_name, u.display_name,
                    u.department_id, d.name AS department_name,
                    u.role_id, r.code AS role_code, r.name AS role_name,
                    u.is_active
                FROM dbo.users u
                INNER JOIN dbo.roles r       ON r.id = u.role_id
                LEFT  JOIN dbo.departments d ON d.id = u.department_id
                WHERE u.email = @Email;";

            using (var con = Database.OpenConnection())
            using (var cmd = new SqlCommand(sql, con))
            {
                cmd.Parameters.Add("@Email", SqlDbType.NVarChar, 190).Value = email.Trim();
                using (var rd = cmd.ExecuteReader())
                {
                    if (!rd.Read()) return null;

                    string hash = rd.GetString(rd.GetOrdinal("password_hash"));
                    if (!PasswordHasher.Verify(password, hash)) return null;

                    bool active = rd.GetBoolean(rd.GetOrdinal("is_active"));
                    if (!active) return null;

                    return MapUser(rd);
                }
            }
        }

        public static void TouchLastLogin(long userId)
        {
            const string sql = "UPDATE dbo.users SET last_login_at = SYSUTCDATETIME() WHERE id = @Id;";
            using (var con = Database.OpenConnection())
            using (var cmd = new SqlCommand(sql, con))
            {
                cmd.Parameters.Add("@Id", SqlDbType.BigInt).Value = userId;
                cmd.ExecuteNonQuery();
            }
        }

        public static void LogActivity(long? userId, string action, string ip, string userAgent)
        {
            try
            {
                const string sql = @"
                    INSERT INTO dbo.activity_logs (user_id, action, ip_address, user_agent)
                    VALUES (@UserId, @Action, @Ip, @Ua);";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.Add("@UserId", SqlDbType.BigInt).Value = (object)userId ?? DBNull.Value;
                    cmd.Parameters.Add("@Action", SqlDbType.NVarChar, 80).Value = action ?? "";
                    cmd.Parameters.Add("@Ip", SqlDbType.VarChar, 45).Value = (object)ip ?? DBNull.Value;
                    cmd.Parameters.Add("@Ua", SqlDbType.NVarChar, 500).Value = (object)userAgent ?? DBNull.Value;
                    cmd.ExecuteNonQuery();
                }
            }
            catch { }
        }

        // ═════════════════════════════════════════════════════════
        // REGISTER
        // ═════════════════════════════════════════════════════════
        public static bool EmailExists(string email)
        {
            if (string.IsNullOrWhiteSpace(email)) return false;
            const string sql = "SELECT COUNT(1) FROM dbo.users WHERE email = @Email;";
            using (var con = Database.OpenConnection())
            using (var cmd = new SqlCommand(sql, con))
            {
                cmd.Parameters.Add("@Email", SqlDbType.NVarChar, 190).Value = email.Trim();
                return (int)cmd.ExecuteScalar() > 0;
            }
        }

        public static bool EmployeeCodeExists(string code)
        {
            if (string.IsNullOrWhiteSpace(code)) return false;
            const string sql = "SELECT COUNT(1) FROM dbo.users WHERE employee_code = @Code;";
            using (var con = Database.OpenConnection())
            using (var cmd = new SqlCommand(sql, con))
            {
                cmd.Parameters.Add("@Code", SqlDbType.NVarChar, 20).Value = code.Trim();
                return (int)cmd.ExecuteScalar() > 0;
            }
        }

        public static UserAccount Register(
            string fullName, string email, long departmentId,
            string employeeCode, string password)
        {
            if (EmailExists(email)) return null;
            if (!string.IsNullOrWhiteSpace(employeeCode) && EmployeeCodeExists(employeeCode)) return null;

            string firstName, lastName;
            SplitVietnameseName(fullName, out lastName, out firstName);

            string passwordHash = PasswordHasher.Hash(password);

            const string sql = @"
                INSERT INTO dbo.users
                    (employee_code, email, password_hash,
                     first_name, last_name, display_name,
                     department_id, role_id, joined_at)
                OUTPUT INSERTED.id
                VALUES
                    (@EmpCode, @Email, @Pwd,
                     @First, @Last, @Display,
                     @DeptId,
                     (SELECT id FROM dbo.roles WHERE code = N'employee'),
                     CAST(SYSUTCDATETIME() AS DATE));";

            long newId;
            using (var con = Database.OpenConnection())
            using (var cmd = new SqlCommand(sql, con))
            {
                cmd.Parameters.Add("@EmpCode", SqlDbType.NVarChar, 20).Value =
                    string.IsNullOrWhiteSpace(employeeCode) ? (object)DBNull.Value : employeeCode.Trim();
                cmd.Parameters.Add("@Email", SqlDbType.NVarChar, 190).Value = email.Trim();
                cmd.Parameters.Add("@Pwd", SqlDbType.NVarChar, 255).Value = passwordHash;
                cmd.Parameters.Add("@First", SqlDbType.NVarChar, 60).Value = firstName;
                cmd.Parameters.Add("@Last", SqlDbType.NVarChar, 60).Value = lastName;
                cmd.Parameters.Add("@Display", SqlDbType.NVarChar, 120).Value = fullName.Trim();
                cmd.Parameters.Add("@DeptId", SqlDbType.BigInt).Value = departmentId;

                newId = Convert.ToInt64(cmd.ExecuteScalar());
            }

            return GetById(newId);
        }

        private static void SplitVietnameseName(string full, out string last, out string first)
        {
            full = (full ?? "").Trim();
            if (full.Length == 0) { last = "?"; first = "?"; return; }

            int idx = full.LastIndexOf(' ');
            if (idx < 0) { last = full; first = full; return; }

            last = full.Substring(0, idx).Trim();
            first = full.Substring(idx + 1).Trim();

            if (string.IsNullOrEmpty(last)) last = first;
            if (string.IsNullOrEmpty(first)) first = last;
        }

        // ═════════════════════════════════════════════════════════
        // QUERIES
        // ═════════════════════════════════════════════════════════
        public static UserAccount GetById(long id)
        {
            const string sql = @"
                SELECT u.id, u.employee_code, u.email, u.first_name, u.last_name, u.display_name,
                       u.department_id, d.name AS department_name,
                       u.role_id, r.code AS role_code, r.name AS role_name,
                       u.is_active
                FROM dbo.users u
                INNER JOIN dbo.roles r       ON r.id = u.role_id
                LEFT  JOIN dbo.departments d ON d.id = u.department_id
                WHERE u.id = @Id;";
            using (var con = Database.OpenConnection())
            using (var cmd = new SqlCommand(sql, con))
            {
                cmd.Parameters.Add("@Id", SqlDbType.BigInt).Value = id;
                using (var rd = cmd.ExecuteReader())
                    return rd.Read() ? MapUser(rd) : null;
            }
        }

        public static List<KeyValuePair<long, string>> GetActiveDepartments()
        {
            var list = new List<KeyValuePair<long, string>>();
            const string sql = @"
                SELECT id, name FROM dbo.departments
                WHERE is_active = 1
                ORDER BY name;";
            using (var con = Database.OpenConnection())
            using (var cmd = new SqlCommand(sql, con))
            using (var rd = cmd.ExecuteReader())
            {
                while (rd.Read())
                    list.Add(new KeyValuePair<long, string>(
                        rd.GetInt64(0), rd.GetString(1)));
            }
            return list;
        }

        private static UserAccount MapUser(SqlDataReader rd)
        {
            return new UserAccount
            {
                Id = rd.GetInt64(rd.GetOrdinal("id")),
                EmployeeCode = SafeStr(rd, "employee_code"),
                Email = rd.GetString(rd.GetOrdinal("email")),
                FirstName = rd.GetString(rd.GetOrdinal("first_name")),
                LastName = rd.GetString(rd.GetOrdinal("last_name")),
                DisplayName = SafeStr(rd, "display_name"),
                DepartmentId = rd.IsDBNull(rd.GetOrdinal("department_id")) ? (long?)null : rd.GetInt64(rd.GetOrdinal("department_id")),
                DepartmentName = SafeStr(rd, "department_name"),
                RoleId = rd.GetInt64(rd.GetOrdinal("role_id")),
                RoleCode = rd.GetString(rd.GetOrdinal("role_code")),
                RoleName = rd.GetString(rd.GetOrdinal("role_name")),
                IsActive = rd.GetBoolean(rd.GetOrdinal("is_active"))
            };
        }

        private static string SafeStr(SqlDataReader rd, string col)
        {
            int i = rd.GetOrdinal(col);
            return rd.IsDBNull(i) ? null : rd.GetString(i);
        }

        // ═════════════════════════════════════════════════════════
        // SESSION
        // ═════════════════════════════════════════════════════════
        public static void SignIn(HttpSessionState session, UserAccount user)
        {
            session[SESSION_USER_ID] = user.Id;
            session[SESSION_USER_EMAIL] = user.Email;
            session[SESSION_USER_NAME] = user.FullName;
            session[SESSION_ROLE_CODE] = user.RoleCode;
        }

        public static void SignOut(HttpSessionState session)
        {
            session.Clear();
            session.Abandon();
        }

        public static bool IsAuthenticated(HttpSessionState session)
        {
            return session != null && session[SESSION_USER_ID] != null;
        }

        public static bool IsAdmin(HttpSessionState session)
        {
            if (!IsAuthenticated(session)) return false;
            return (session[SESSION_ROLE_CODE] as string) == "admin";
        }

        public static bool CanAccessAdminArea(HttpSessionState session)
        {
            if (!IsAuthenticated(session)) return false;
            var code = session[SESSION_ROLE_CODE] as string;
            return code == "admin" || code == "organizer";
        }

        public static UserAccount CurrentUser(HttpSessionState session)
        {
            if (!IsAuthenticated(session)) return null;
            long id = Convert.ToInt64(session[SESSION_USER_ID]);
            return GetById(id);
        }

        public static string GetRedirectUrl(UserAccount user)
        {
            if (user == null) return "~/Account/Login.aspx";
            return (user.RoleCode == "admin" || user.RoleCode == "organizer")
                ? "~/Admin/Dashboard.aspx"
                : "~/User/UserHome.aspx";
        }

        // ═════════════════════════════════════════════════════════
        // SEED: tự tạo admin mặc định khi DB chưa có
        // ═════════════════════════════════════════════════════════
        public static void EnsureSeedAdmin()
        {
            if (EmailExists("admin@congty.com")) return;

            long? itDeptId = null;
            const string getDept = "SELECT TOP 1 id FROM dbo.departments WHERE code = N'IT';";
            using (var con = Database.OpenConnection())
            using (var cmd = new SqlCommand(getDept, con))
            {
                var o = cmd.ExecuteScalar();
                if (o != null && o != DBNull.Value) itDeptId = Convert.ToInt64(o);
            }

            const string sql = @"
                INSERT INTO dbo.users
                    (employee_code, email, password_hash,
                     first_name, last_name, display_name,
                     department_id, role_id, joined_at)
                VALUES
                    (@EmpCode, @Email, @Pwd,
                     @First, @Last, @Display,
                     @DeptId,
                     (SELECT id FROM dbo.roles WHERE code = N'admin'),
                     CAST(SYSUTCDATETIME() AS DATE));";

            using (var con = Database.OpenConnection())
            using (var cmd = new SqlCommand(sql, con))
            {
                cmd.Parameters.Add("@EmpCode", SqlDbType.NVarChar, 20).Value = "ADM-001";
                cmd.Parameters.Add("@Email", SqlDbType.NVarChar, 190).Value = "admin@congty.com";
                cmd.Parameters.Add("@Pwd", SqlDbType.NVarChar, 255).Value = PasswordHasher.Hash("admin123");
                cmd.Parameters.Add("@First", SqlDbType.NVarChar, 60).Value = "Quản trị";
                cmd.Parameters.Add("@Last", SqlDbType.NVarChar, 60).Value = "Hệ thống";
                cmd.Parameters.Add("@Display", SqlDbType.NVarChar, 120).Value = "Quản trị viên";
                cmd.Parameters.Add("@DeptId", SqlDbType.BigInt).Value =
                    itDeptId.HasValue ? (object)itDeptId.Value : DBNull.Value;
                cmd.ExecuteNonQuery();
            }
        }
    }
}   