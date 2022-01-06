using System;
using System.Net.Http;
using Newtonsoft.Json;

namespace Name
{
    class Program
    {
        private static readonly string API_KEY = "aeae39958f5397d0d7792e773d959376";
        private static readonly string[] VALID_UNITS = {"imperial", "metric"};
        public static async Task Main(string[] args){ 
            if(!(args.Length == 2 || args.Length == 4)){
                Console.Error.WriteLine("ERROR: Not Enough Args");
                Environment.Exit(-1);
            }
            if(!(args[0].Equals("--city") || args[0].Equals("-c"))){
                Console.Error.WriteLine("ERROR: City flag isn't valid");
                Environment.Exit(-1);
            }

            string city = args[1];
            string units;
            try{
                if(!(args[2].Equals("--units") || args[2].Equals("-u"))){
                    Console.Error.WriteLine("ERROR: Units flag isn't valid");
                    Environment.Exit(-1);
                }
                units = args[3];

                if(Array.IndexOf(VALID_UNITS, units) == -1){
                    Console.Error.WriteLine("ERROR: This is not Valid Unit");
                    Environment.Exit(-1);
                }
            }catch(IndexOutOfRangeException){
                units = "metric";
            }
     
            await GetCurrentWeather(city, units);
        }

        static async Task GetCurrentWeather(string city, string units)
        {
            
            string url = generateUrl(city, units);

            HttpClient client = new HttpClient();
            string responseString = "";
            try
            {
                responseString = await client.GetStringAsync(url);
            }
            catch (System.Net.Http.HttpRequestException)
            {
                Console.Error.WriteLine("ERROR: HttpRequest Error");
                Environment.Exit(-1);
            }

            Root? myDeserializedClass = JsonConvert.DeserializeObject<Root>(responseString);
            if (myDeserializedClass != null){
                print(myDeserializedClass);
            }
        }

        static string generateUrl(string city, string units){
            return $"https://api.openweathermap.org/data/2.5/weather?appid={API_KEY}&units={units}&q={city}";
        }


        static void print(object str){
            Console.WriteLine(str);
        }
    }


    public class Root
    {
        public Root(){
            this.main = new Main();
            this.wind = new Wind();
            this.name = new String("");
        }
        
        public override string ToString(){
            string str = $"{name}|{main.temp}|{wind.speed}|{main.humidity}|{main.pressure}";
            return str;
        }
        public Main main { get; set; }
        public Wind wind { get; set; }
        public string name { get; set; }
        public class Main
        {
            public double temp { get; set; }
            public int pressure { get; set; }
            public int humidity { get; set; }
        }
        public class Wind
        {
            public double speed { get; set; }
        }
    }

}
