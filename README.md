# Programowanie Aplikacji w Chmurze Obliczeniowej

      Marek Prokopiuk
      grupa dziekańska: 6.7
      numer albumu: 097710
## Zadanie 1<br>Część obowiązkowa.
<p align="justify">Przedstawione zostało rozwiązanie części obowiązkowej zadania 1 w ramach laboratorium z przedmiotu Programowanie Aplikacji w Chmurze obliczeniowej. Zostały przygotowane odpowiednie pliki, a także wykorzystane polecenia do zbudowania oraz właściwego wykorzystania docelowego obrazu. Zreazlizowano plik Dockerfile dla aplikacji webowej uruchamianej w oparciu o serwer Nginx oraz budowanej z wykorzystaniem metody wieloetapowej.</p>

---

### 1. Stworzenie programu serwera
<p align="justify">Na początku należało napisać program w dowolnym języku programowania, który miał po uruchomieniu kontenera pozostawić w logach informację o dacie uruchomienia, imieniu i nazwisku autora serwera oraz porcie TCP, na którym serwer nasłuchuje na zgłoszenie. W przeglądarce natomiast miała zostać wyświetlona strona informująca o adresie IP klienta oraz dacie i godzinie w jego strefie czasowej, otrzymanej na podstawie tego adresu IP.</p>
<p align="justify">Zadanie to zostało zrealizowane w języku JavaScript (plik <a href="https://github.com/MarekP21/pawcho_zadanie1/blob/main/server.js">server.js</a>) z wykorzystaniem bibliotek <i>express</i> do obsługi żądań HTTP oraz <i>moment-timezone</i> do obsługi stref czasowych. Wykorzystane wersje tych bibliotek należało również wskazać w zależnościach w pliku <a href="https://github.com/MarekP21/pawcho_zadanie1/blob/main/package.json">package.json</a>. Poniżej został przedstawiony cały program serwera napisany na potrzeby tego zadania wraz z potrzebnymi komentarzami.</p><br>

```diff
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
```

---

### 2. Opracowanie pliku Dockerfile
<p align="justify">Kolejnym elementem zadania było przygotowanie odpowiedniego pliku Dockerfile, który miał pozwolić na zbudowanie obrazu kontenera realizującego funkcjonalność stworzonego wcześniej serwera. Przy opracowaniu pliku Dockerfile wykorzystane zostało wieloetapowe budowanie obrazu. Użyto warstwy <i>scratch</i> jako punktu wyjściowego oraz <i>nginx:alpine</i> jako ostatecznego obrazu.</p> 
<p align="justify">Zastosowano optymalizację pod kątem funkcjonowania cache-a poprzez skopiowanie pliku konfiguracyjnego aplikacji (który zmieniany jest stosunkowo rzadziej niż kod aplikacji) przed wywołaniem instrukcji <i>npm install</i>, aby docker korzystał z pamięci podręcznej. Zdefiniowno także zmienną środowiskową zawierającą wersję aplikacji. Zastosowano <i>healthcheck</i> do monitorowania dostępności serwera. W Dockerfile zawarto również informację o autorze tego pliku w postaci metadanych z imieniem i nazwiskiem.</p>
<p align="justify">Oprócz pliku Dockerfile w celu realizacji zadania potrzebne są następujące pliki:</p>

  - <a href="https://github.com/MarekP21/pawcho_zadanie1/blob/main/server.js">server.js</a> z aplikacją serwera
  - <a href="https://github.com/MarekP21/pawcho_zadanie1/blob/main/nginx.conf">nginx.conf</a> z konfiguracją nginx
  - <a href="https://github.com/MarekP21/pawcho_zadanie1/blob/main/package.json">package.json</a> z odpowiednimi zależnościami
  - <a href="https://github.com/MarekP21/pawcho_zadanie1/blob/main/alpine-minirootfs-3.19.1-x86_64.tar">alpine-minirootfs-3.19.1-x86_64</a> z warstwą bazową obrazu
  
<p>Poniżej została umieszczona cała zawartość pliku <a href="https://github.com/MarekP21/pawcho_zadanie1/blob/main/Dockerfile">Dockerfile</a> wraz z potrzebnymi komentarzami</p><br>

```diff
# Etap 1: Budowanie aplikacji Node.js
# Wykorzystanie warstwy scratch jako punktu wyjściowego,
# aby obrazy były jak najmniejsze
FROM scratch AS first_step

# Utworzenie warstwy bazowej obrazu 
ADD alpine-minirootfs-3.19.1-x86_64.tar /

# Zmienna BASE_VERSION przekazywana do procesu budowy 
# obrazu oraz deklaracja zmiennej Environment
# Jeżeli BASE_VERSION nie będzie posiadało wartości
# to wersja ta będzie wpisana defaultowo jako v1
ARG BASE_VERSION
ENV APP_VERSION=${BASE_VERSION:-v1}

# Instalacja komponentów środowiska roboczego
RUN apk update && \
    apk upgrade && \ 
    apk add --no-cache nodejs npm && \
    rm -rf /var/cache/apk/* 

# Deklaracja katalogu roboczego
WORKDIR /usr/app

# Optymalizacja pod kątem funckjonowania cache-a
# w procesie budowania:
    
# Skopiowanie pliku konfiguracyjnego aplikacji 
# (zmienia się on rzadziej)
COPY ./package.json ./

# Docker będzie korzystać z pamięci podręcznej 
# dla instrukcji npm install, jeśli pliki 
# konfiguracyjne pozostają niezmienione 
RUN npm install && \
    npm cache clean --force && \
    rm -rf /tmp/*

# Kopiowanie kodu aplikacji wewnątrz obrazu
# (zmienia się on częściej)
COPY ./server.js ./

#-----------------------------------------------------------------------
# ETAP 2 Tworzenie obrazu produkcyjnego
FROM nginx:alpine3.19 AS second_step

# Powtórzenie deklaracji zmiennej
ARG BASE_VERSION

# Instalacja curl do obsługi testów healthcheck
# oraz ponowne dodanie Node.js
RUN apk add --update curl && \
    apk add --update nodejs npm && \ 
    rm -rf /var/cache/apk/*

# Zdefiniowanie katalogu roboczego
WORKDIR /usr/app

# Kopiowanie konfiguracji serwera HTTP
COPY --from=first_step /usr/app /usr/share/nginx/html/

# Skopiowanie pliku konfiguracyjnego 
# nginx.conf do katalogu /etc/nginx/conf.d/
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

# Deklaracja katalogu roboczego
WORKDIR /usr/share/nginx/html

# Zdefiniowanie zmiennej środowiskowej z wersją aplikacji
ENV APP_VERSION=${BASE_VERSION:-v1}

# Deklaracja portu aplikacji w kontenerze
EXPOSE 8080

# Monitorowanie dostepnosci serwera
HEALTHCHECK --interval=10s --timeout=1s \
    CMD curl -f http://localhost:8080/ || exit 1

# Zdefiniowanie metadanych o autorze Dockerfile
# imię i nazwisko studenta
LABEL author="Marek Prokopiuk"

# Deklaracja sposobu uruchomienia serwera
CMD ["sh", "-c", "npm start & nginx -g 'daemon off;'"]
#-----------------------------------------------------------------------
```

---

### 3. Zbudowanie obrazu i uruchomienie serwera
<p align="justify">Po przygotowaniu programu serwera oraz opracowaniu pliku Dockerfile należało, korzystając z odpowiednich poleceń zbudować obraz, a na jego podstawie uruchomić działający kontener. W celu zbudowania obrazu wykorzystano następujące polecenie</p> 

      docker build --build-arg BASE_VERSION=ver1 -t local/marek_zad1:v0 .

<p align="justify">Natomiast, żeby utworzyć kontener na podstawie tego obrazu, użyto poniższego polecenia</p>  

      docker run -d -p 8087:8080 --name zad1_kontener local/marek_zad1:v0

<p align="justify">Obraz został zbudowany dwukrotnie, aby pokazać wykorzystanie cache-a przy drugim budowaniu. Pokazano szczegółowe informacje o powstałym obrazie oraz uruchomionym kontenerze, który ma status <i>healthy</i>. Wykorzystane polecenia oraz otrzymane w wyniku ich wywołania rezultaty widać na poniższych zrzutach ekranu.</p>

<p align="center">
  <img src="https://github.com/MarekP21/pawcho_zadanie1/blob/main/screeny/pierwsze_budowanie_obrazu.png" style="width: 80%; height: 80%" /></p>
<p align="center">
  <i>Rys. 1. Pierwsze budowanie obrazu</i>
</p><br>

<p align="center">
  <img src="https://github.com/MarekP21/pawcho_zadanie1/blob/main/screeny/drugie_budowanie_obrazu_wykorzystanie_cache.png" style="width: 80%; height: 80%" /></p>
<p align="center">
  <i>Rys. 2. Drugie budowanie obrazu - wykorzystanie cache</i>
</p><br>

<p align="center">
  <img src="https://github.com/MarekP21/pawcho_zadanie1/blob/main/screeny/utworzenie_kontenera.png" style="width: 80%; height: 80%" /></p>
<p align="center">
  <i>Rys. 3. Uruchomienie kontenera (status healthy)</i>
</p>

<p align="justify">Następnie należało uzyskać informacje, które wygenerował serwer w trakcie uruchamiania. Wykorzystano więc odpowiednie polecenie do sprawdzenia danych pozostawionych w logach.</p>

       docker logs zad1_kontener
       
<p align="justify">Sprawdzono także ile warstw posiada zbudowany obraz. Użyte w tym celu zostało następujące polecenie</p>
    
       docker history local/marek_zad1:v0

<p align="justify">Treść poleceń oraz otrzymane wyniki widać na poniższych rysunkach.</p>
<p align="center">
  <img src="https://github.com/MarekP21/pawcho_zadanie1/blob/main/screeny/informacje_zawarte_w_logach.png" style="width: 80%; height: 80%" /></p>
<p align="center">
  <i>Rys. 4. Informacje zawarte w logach</i>
</p><br>

<p align="center">
  <img src="https://github.com/MarekP21/pawcho_zadanie1/blob/main/screeny/warstwy_obrazu.png" style="width: 80%; height: 80%" /></p>
<p align="center">
  <i>Rys. 5. Warstwy zbudowanego obrazu</i>
</p>

<p align="justify">Na koniec sprawdzono poprawne działanie systemu. Wszystko działało prawidłowo, a efekt z okna przeglądarki został pokazany na poniższym zrzucie ekranu.</p>
<p align="center">
  <img src="https://github.com/MarekP21/pawcho_zadanie1/blob/main/screeny/wynik_przegladarka.png" style="width: 80%; height: 80%" /></p>
<p align="center">
  <i>Rys. 6. Potwierdzenie poprawnego działania systemu</i>
</p>

---

### 4. Wykorzystanie narzędzia Docker Scount
<p align="justify">Po zrealizowaniu całego zadania trzeba było jeszcze wykazać, że żadne składowe powstałego obrazu nie uzyskują oceny CVSS w zakresie High lub Critical. Wykorzystane zostało w tym celu narzędzie Docker Scout i dostępne w nim następujące polecenia</p>

       docker scout quickview local/marek_zad1:v0
       
<p align="justify">oraz</p>
    
       docker scout cves local/marek_zad1:v0

<p align="justify">Okazało się, że utworzony obraz spełnia warunek i nie uzyskuje ocen High ani Critical. Występują jedynie trzy oceny Medium związane z wersjami pakietów. Wynik wykonania powyższych poleceń widać na poniższych zrzutach ekranu.</p>
<p align="center">
  <img src="https://github.com/MarekP21/pawcho_zadanie1/blob/main/screeny/docker_scout_quickview.png" style="width: 80%; height: 80%" /></p>
<p align="center">
  <i>Rys. 7. Wynik polecenia docker scout quickview</i>
</p><br>

<p align="center">
  <img src="https://github.com/MarekP21/pawcho_zadanie1/blob/main/screeny/docker_scout_cves.png" style="width: 80%; height: 80%" /></p>
<p align="center">
  <i>Rys. 8. Wynik polecenia docker scout cves</i>
</p>

---
