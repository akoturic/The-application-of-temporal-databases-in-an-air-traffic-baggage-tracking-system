# Primjena temporalne baze podataka u sustavu za praćenje prtljage u zračnom prometu

## Opis

U ovom projektu implementirana je baza podataka za praćenje prtljage u zračnom prometu i demonstrirana njena korisnost kroz razne upite implementirane upravo za ovu bazu podataka.

## Struktura Projekta

* **`ERD.png`**: MEV dijagram.
* **`tables.sql`**: SQL kod za implementaciju tablica i indexa.
* **`triggers.sql`**: SQL kod za implementaciju okidača.
* **`functions.sql`**: SQL kod za implementaciju funkcija register_baggage_and_itinerary() i log_baggage_status() koje se koriste za unosenje podataka u bazu.
* **`data_insert.sql`**: SQL kod za unos podataka u tablice Airport, Passanger i Location.
* **`data_insert2.sql`**: SQL kod za unos podataka u tablice Flight, Baggage, BaggageItinerary i BaggageHistory. Podaci unešeni na temelju kreiranih scenarija.
* **`queries.sql`**: SQL kod za upite.
* **`Koturic_diplomskiRad.pdf`**: Diplomski rad - "Primjena temporalne baza podataka u sustavu za pračenje prtljage u zračnom prometu".
