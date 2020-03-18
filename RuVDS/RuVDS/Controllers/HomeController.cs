using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using RuVDS.Models;
using System.Xml;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json;
using System.Xml.Linq;
using Microsoft.Data.SqlClient;
using System.Data;

namespace RuVDS.Controllers
{
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;
        private readonly AppDbContext _context;

        public HomeController(ILogger<HomeController> logger, AppDbContext context)
        {
            _logger = logger;
            _context = context;
        }

        public IActionResult Index()
        {
            var totalUsageTime = new SqlParameter("totalUsageTime", System.Data.SqlDbType.Time) {
                Direction = ParameterDirection.Output,              
            };

            List<GetInfoAboutServers> servers = _context.GetInfoAboutServers.FromSqlInterpolated($"[get_info_about_servers] {totalUsageTime} OUTPUT").ToList();
            ViewBag.result = servers;
            ViewBag.totalUsageTime = totalUsageTime.Value;
            return View("~/Views/Home/show.cshtml");
        }

        [HttpGet]
        [Obsolete]
        public void AddServer()
        {
            _context.Database.ExecuteSqlCommand($"[add_server]");           
        }

        [Obsolete]
        public void RemoveServers(string jsonOnRemoveServers)
        {
            ServerOnRemoved[] serversOnDelete = JsonConvert.DeserializeObject<ServerOnRemoved[]>(jsonOnRemoveServers);
      
            XDocument xmlServervOnDelete = new XDocument();
            XElement rootNode = new XElement("servers");
            foreach (var currentServerOnRemove in serversOnDelete)
            {
                XElement currentServer = new XElement("server");
                XAttribute attrubuteCurrentServer = new XAttribute("id", currentServerOnRemove.idServer);
                currentServer.Add(attrubuteCurrentServer);
                rootNode.Add(currentServer);
            }
            xmlServervOnDelete.Add(rootNode);
            
            _context.Database.ExecuteSqlCommand($"[delete_server] {xmlServervOnDelete.ToString()}");
        
        }

        [Obsolete]
        public void DeleteAllServers()
        {
            _context.Database.ExecuteSqlCommand("[Delete_All_Servers]");
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}
