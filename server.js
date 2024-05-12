// Import bibliotek: express do żądań HTTP
// oraz moment-timezone do obsługi stref czasowych
const express = require('express'); 
const moment = require('moment-timezone'); 

const app = express();

// Określenie portu na którym będzie działać serwer,
// infomacji o autorze serwera
// oraz początkowego czasu uruchomienia serwera
const port = 8080; 
const author = "Marek Prokopiuk";
const serverStartTime = new Date();

app.get('/', async (req, res) => {

    // Pobranie adresu IP klienta łączącego się z serwerem
    const clientIp = req.ip;

    // Pobranie czasu w strefie czasowej klienta na podstawie jego adresu IP
    const clientTimezone = moment.tz.guess();
    const clientTime = moment().tz(clientTimezone).format('YYYY-MM-DD HH:mm:ss');
 
    // Wyświetlenie informacji w przeglądarce
    res.send(`
        <h2>Informacje o kliencie</h2>
        <p>Adres IP klienta: ${clientIp}</p>
        <p>Data i godzina w strefie czasowej klienta: ${clientTime}</p>
    `);
});

// Uruchomienie serwera na określonym porcie
app.listen(port, () => {
    // Pozostawienie w logach odpowiednich informacji
    console.log(`Data uruchomienia serwera: ${serverStartTime}`);
    console.log(`Imię i nazwisko autora serwera: ${author}`);
    console.log(`Port, na którym serwer nasłuchuje: ${port}`);
});
