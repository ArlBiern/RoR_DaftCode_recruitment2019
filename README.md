# Zadanie rekrutacyjne - GrillMaster

Na zewnątrz jest już coraz cieplej i powoli rozpoczyna się sezon grillowy. Ale zanim będziemy mogli zaprosić znajomych na imprezę nad Wisłą musimy zrobić zakupy. Węgiel, chipsy, piwo, kiełbaski - a czym więcej ludzi tym dłuższa będzie nasza lista zakupów. Na szczęście sklep w którym chcemy to wszystko kupić oferuje kilka promocji, dzięki którym możemy obniżyć końcową cenę.

Twoim zadaniem będzie stworzenie API, które udostępni następujące funkcjonalności:

1. Zarządzanie listą zakupów (koszykiem)
2. Definiowanie dostępnych promocji
3. Automatyczny wybór najlepszych promocji i obliczanie ostatecznej kwoty zakupów

Oceniane będą:
- Prawidłowy format odpowiedzi
- Kompletność implementacji
- Jakość kodu
- Staranność rozwiązania
- Poprawność odpowiedzi

W aplikacji, w pliku `config/routes.rb` są już zdefiniowane wszystkie ścieżki, które chcemy mieć dostępne. Stworzony jest także model `Product` a w `db/seeds.rb` tworzona jest lista produktów dostępnych w sklepie. Podczas rozwiązywania zadania nie modyfikuj żadnego z tych dwóch plików.

## 1. Zarządzanie listą zakupów

W ramach tego punktu, Twoim zadaniem jest dodanie kontrolera pozwalającego na zarządzanie produktami w koszyku zgodnie z poniższymi wymaganiami:

- W celu dodania produktu do koszyka wysyłamy jego `id` do `POST /cart/items`
- W jednym zapytaniu możemy dodać/zmodyfikować kilka sztuk produktu przesyłając atrybut `quantity` (domyślnie 1)
- Produkt z koszyka usuwamy zmieniając jego `quantity` na 0
- W odpowiedzi po dodaniu/zmianie produktu dostajemy stan całego koszyka

Oczywiście, żeby poznać `id` produktu potrzebny będzie kontroler obsługujący listowanie produktów.

Przykładowe zapytania  i spodziewane odpowiedzi przy dodawaniu rzeczy do koszyka:

```json
POST /cart/items

Body: 
{
  "product_id": 5,
  "quantity": 5
}

Response:
{
  "items":
  [
    { "id": 1, "quantity": 5, "product": { "id": 5, "name": "Beer", "price": 4.0 } }
  ],
  "discounts": []
}
```

```json
POST /cart/items

Body:
{
  "product_id": 8
}

Response:
{
  "items":
  [
    { "id": 1, "quantity": 5, "product": { "id": 5, "name": "Beer", "price": 4.0 } },
    { "id": 2, "quantity": 1, "product": { "id": 8, "name": "Coal", "price": 7.0 } }
  ],
  "discounts": []
}
```

Przykładowe zapytanie modyfikujące zawartość koszyka:

```json
PUT /cart/items/2

Body:
{
  "quantity": 2
}

Response:
{
  "items":
  [
    { "id": 1, "quantity": 5, "product": { "id": 5, "name": "Beer", "price": 4.0 } },
    { "id": 2, "quantity": 2, "product": { "id": 8, "name": "Coal", "price": 7.0 } }
  ],
  "discounts": []
}
```

## 2. Definiowanie dostępnych promocji

Oprócz produktów do koszyka możemy dodać też dostępne promocje. Będą one następnie użyte przy podliczaniu zawartości. Na nasze potrzeby przyjmujemy następujące założenia:

- Istnieją dwa rodzaje promocji: `set` i `extra`
- `set` pozwala połączyć kilka produktów w jeden zestaw o niższej cenie
- `set` może wymagać więcej niż jednej sztuki produktu
- `extra` pozwala dostać jedną sztukę produktu bezpłatnie przy zakupie określonej liczby sztuk (np. 3 sztuki w cenie 2)
-  `extra` może być zdefiniowany dla wielu róznych produktów na raz (ale działa tylko dla produktów jednego typu) 

Przykładowe zapytania dodające promocje do koszyka:

```json
POST /cart/discounts

Body:
{
  "kind": "set",
  "name": "BBQ pack",
  "product_ids": [4, 5, 5, 8],
  "price": 11.99
}

Response:
{
  "items":
  [
    { "id": 1, "quantity": 5, "product": { "id": 5, "name": "Beer", "price": 4.0 } },
    { "id": 2, "quantity": 2, "product": { "id": 8, "name": "Coal", "price": 7.0 } }
  ],
  "discounts":
  [
    { "id": 1, "kind": "set", "name": "BBQ pack", "product_ids": [4, 5, 5, 8], "price": 11.99 }
  ]
}
```

```json
POST /cart/discounts

Body:
{
  "kind": "extra",
  "name": "Three for two",
  "product_ids": [3, 5],
  "count": 2
}

Response:
{
  "items":
  [
    { "id": 1, "quantity": 5, "product": { "id": 5, "name": "Beer", "price": 4.0 } },
    { "id": 2, "quantity": 2, "product": { "id": 8, "name": "Coal", "price": 7.0 } }
  ],
  "discounts":
  [
    { "id": 1, "kind": "set", "name": "BBQ pack", "product_ids": [4, 5, 5, 8], "price": 11.99 },
    { "id": 2, "kind": "extra", "name": "Three for two", "product_ids": [3, 5], "count": 2 }
  ]
}
```

## 3. Automatyczny wybór najlepszych promocji i obliczanie ostatecznej kwoty zakupów

Ostani etap który musisz zaimplementować będzie umożliwiał obliczenie kwoty produktów w koszyku. Informacje te możemy dostać po prostu robiąc zapytanie  `GET /cart/total`. Przy wybieraniu promocji należy pamietać o kilku zasadach:

- Każdy produkt może być użyty tylko w jednej promocji (promocje nie łączą się)
- Produkt, który dostajemy bezpłatnie z promocji typu `extra` nie może być zastosowany do innych promocji
- Każdą promocję możemy stosować wielokrotnie - tak długo jak długo mamy dostępne produkty
- Liczba produktów w podsumowaniu moze być większa niż produktów w koszyku (np. o dodatkowy produkt z promocji typu `extra`)
- Do koszyka możemy automatycznie dodać produkty spoza listy `items` pod warunkiem, że spowodują one obniżenie końcowej kwoty zakupów (np. są potrzebne do skorzystania z promocji typu `set`)

Przykładowa odpowiedź dla stanu koszyka z poprzedniego przykładu:

```json
GET /cart/total

No Body

Response:
{
  "sets":
  [
    {
      "name": "BBQ pack",
      "products":
      [
        { "id": 4, "name": "Sausage", "price": 5.0 },
        { "id": 5, "name": "Beer", "price": 4.0 },
        { "id": 5, "name": "Beer", "price": 4.0 },
        { "id": 8, "name": "Coal", "price": 7.0 }
      ],
      "total": 12.99
    }
  ],
  "extras":
  [
    {
      "name": "Three for two",
      "products":
      [
        { "id": 5, "name": "Beer", "price": 4.0 },
        { "id": 5, "name": "Beer", "price": 4.0 },
        { "id": 5, "name": "Beer", "price": 4.0 }
      ],
      "total": 8.0
    }
  ],
  "regular_products":
  [
    { "id": 8, "name": "Coal", "price": 7.0 }
  ],
  "regular price": 34.0
}
```

### Dlaczego spodziewamy się właśnie takiej odpowiedzi?

Na liscie zakupów mieliśmy 5 piw po 4 za sztukę i 2 węgle po 7. W sumie, bez żadnych promocji, daje to kwotę 34.

Węgiel i dwa piwa możemy zgrupować dzięki promocji typu `set` pod warunkiem dodania do koszyka jednej kiełbasy. Taki zestaw kosztuje 12,99, a sam węgiel i dwa piwa bez promocji kosztują 15 - zatem dodanie produktu do koszyka pozwala nam obniżyć kwotę końcową. Do zakupienia zostały nam jeszcze 3 piwa, więc płacimy za dwa a trzecie dostaniemy z promocji typu `extra`. Drugi węgiel bierzemy już bez promocji. Ostatecznie, do zapłaty mamy zatem 27,99. Zaoszczędziliśmy w ten sposób 6,01.

Inną możliwością byłoby dwukrotne zastosowanie promocji `extra` i dostanie 6 piw w cenie czterech, ale wtedy ostateczna kwota do zapłaty wyniesie 30, czyli zaoszczędzimy tylko 4.

Ostatnim wariantem, który warto było rozważyć jest dwukrotne zastosowanie promocji `set`. W promocji kupimy zatem 4 piwa i 2 węgle, a ostatnie piwo kupimy już bez promocji. W ten sposób zapłacimy 29,98, więc też więcej niż w wariancie pierwszym.
