using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace Eventhub.App_Code
{
    /// <summary>
    /// Helper tạo kết nối SQL Server.
    /// Đọc connectionString có name="EventHub" trong Web.config.
    /// </summary>
    public static class Database
    {
        public static string ConnectionString
        {
            get
            {
                var cs = ConfigurationManager.ConnectionStrings["EventHub"];
                if (cs == null || string.IsNullOrWhiteSpace(cs.ConnectionString))
                    throw new System.Exception(
                        "Thiếu connectionString 'EventHub' trong Web.config!");
                return cs.ConnectionString;
            }
        }

        /// <summary>
        /// Tạo 1 kết nối mới đã mở sẵn.
        /// Cách dùng: using (var con = Database.OpenConnection()) { ... }
        /// </summary>
        public static SqlConnection OpenConnection()
        {
            var con = new SqlConnection(ConnectionString);
            con.Open();
            return con;
        }
    }
}