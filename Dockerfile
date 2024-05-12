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