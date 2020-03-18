using System;
using System.ComponentModel.DataAnnotations;
namespace RuVDS.Models
{
    public class GetInfoAboutServers
    {
        [Key]
        public int Id { get; set; }
        public DateTime? create_datetime { get; set; }
        public DateTime? remove_datetime { get; set; }
        public TimeSpan time_active { get; set; }
    }
}
