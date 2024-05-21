#!/bin/bash
# Author           : Hubert Szymczak
# Created On       : 28.05.2023
# Last Modified By : Hubert Szymczak
# Last Modified On : 03.06.2023
# Version          : 1.0.0
# Description      :
# Skrypt "Editor" to aplikacja do edycji obrazów, umożliwiająca m.in. przekształcanie na czarno-białe, skalowanie, dodawanie efektu blur, dodawanie 
# tekstu, zmianę # typu obrazu, obrót, dodawanie kształtów oraz dodawanie ramek.
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

# Wersja programu
VERSION="1.0.0"

# Przykładowe zmienne, które będą ustawiane przez opcje
filename=""
blur_radius=0
blackwhite=false
# Funkcja wyświetlająca pomoc
print_usage() {
  echo "Użycie: $0 -f <plik> [-v] [-o <plik_wyjsciowy>]"
  echo " -f <plik>: Określa nazwę pliku"
  echo " -o <plik_wyjsciowy>: Określa nazwę pliku wyjściowego"
  echo " -v: Wyswietla wersje programu"
  echo " -W: Dodaje blur"
  echo " -B: Zmiana zdjecia na czarno-biale"
}

# Funkcja wyświetlająca wersję programu
print_version() {
  echo "Wersja programu Editor: $VERSION"
}
resize=false
# Parsowanie opcji
while getopts ":vf:o:hW:B" opt; do
  case $opt in
    v)
      print_version
      exit 0
      ;;
    f)
      filename=$OPTARG
      ;;
    o)
      output_file=$OPTARG
      ;;
    h)
      print_usage
      exit 0
      ;;
    W)
      blur=true
      blur_radius=$OPTARG
      ;;
    B)
      blackwhite=true
      ;;
    \?)
      echo "Nieznana opcja: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Opcja -$OPTARG wymaga argumentu." >&2
      exit 1
      ;;
  esac
done
    
# Sprawdzenie czy ImageMagick jest zainstalowany
check_imagemagick_installed() {
  if ! command -v convert &>/dev/null; then
    return 1
  fi
}

# Instalacja ImageMagick
install_imagemagick() {
  if ! check_imagemagick_installed; then
    echo "Instalowanie ImageMagick..."
    if command -v apt-get &>/dev/null; then
      sudo apt-get update
      sudo apt-get install ImageMagick -y
    elif command -v yum &>/dev/null; then
      sudo yum install ImageMagick -y
    else
      echo "Nie można zainstalować ImageMagick. Sprawdź, czy masz odpowiedni menedżer pakietów zainstalowany."
      exit 1
    fi
    echo "ImageMagick został zainstalowany."
  fi
}

# Sprawdzenie i instalacja ImageMagick
install_imagemagick

# Znalezienie ścieżki do polecenia convert
convert_path=$(command -v convert)

# Zamiana zdjęcia na czarno-białe
convert_to_black_and_white() {
  input_file=$1
  output_file=$2

  chmod +r "$input_file"  # Dodanie uprawnień do odczytu pliku
  chmod +w "$output_file"  # Dodanie uprawnień do zapisu pliku

  $convert_path "$input_file" -type grayscale "$output_file"

  zenity --info --title="Sukces" --text="Obraz został przekształcony na czarno-biały."
}
if [ "$blackwhite" = true ]; then
  convert_to_black_and_white "$filename" "$output_file"
  exit 0
fi
# Skalowanie obrazu
scale_image() {
  input_file=$1
  output_file=$2

  width=$(zenity --entry --title "Skalowanie obrazu" --text "Podaj nową szerokość:")
  height=$(zenity --entry --title "Skalowanie obrazu" --text "Podaj nową wysokość:")

  $convert_path "$input_file" -resize "${width}x${height}" "$output_file"

  zenity --info --title="Sukces" --text="Obraz został przeskalowany."
}

# Dodawanie blur
add_blur() {
  input_file=$1
  output_file=$2

  radius=$(zenity --entry --title "Dodawanie blur" --text "Podaj promień blur:")
  $convert_path "$input_file" -blur 0x"$radius" "$output_file"

  zenity --info --title="Sukces" --text="Blur został dodany do obrazu."
}

add_blur2() {
  input_file=$1
  output_file=$2
  radius=$3
  $convert_path "$input_file" -blur 0x"$radius" "$output_file"

}

if [ "$blur" = true ]; then
  add_blur2 "$filename" "$output_file" "$blur_radius"
  exit 0
fi
# Dodawanie tekstu
add_text() {
  input_file=$1
  output_file=$2

  text=$(zenity --entry --title "Dodawanie tekstu" --text "Podaj tekst:")
  font=$(zenity --font-selection --title "Dodawanie tekstu" --text "Wybierz czcionkę:")
  size=$(zenity --entry --title "Dodawanie tekstu" --text "Podaj rozmiar czcionki:")
  color=$(zenity --color-selection --title "Dodawanie tekstu" --text "Wybierz kolor tekstu:")
  x=$(zenity --entry --title "Dodawanie tekstu" --text "Podaj współrzędną x:")
  y=$(zenity --entry --title "Dodawanie tekstu" --text "Podaj współrzędną y:")

  $convert_path "$input_file" -fill "$color" -font "$font" -pointsize "$size" -annotate +"$x"+"$y" "$text" "$output_file"

  zenity --info --title="Sukces" --text="Tekst został dodany do obrazu."
}

# Zmiana typu obrazu
change_image_type() {
  input_file=$1
  output_file=$2

  type=$(zenity --list --title "Zmiana typu obrazu" --text "Wybierz nowy typ obrazu:" --radiolist --column "" --column "Typ" FALSE "PNG" FALSE "JPEG" FALSE "GIF")

  $convert_path "$input_file" "$type:$output_file"

  zenity --info --title="Sukces" --text="Typ obrazu został zmieniony."
}

# Obrót obrazu
rotate_image() {
  input_file=$1
  output_file=$2

  angle=$(zenity --entry --title "Obrót obrazu" --text "Podaj kąt obrotu (w stopniach):")

  $convert_path "$input_file" -rotate "$angle" "$output_file"

  zenity --info --title="Sukces" --text="Obraz został obrócony."
}

# Dodawanie kształtów
add_shapes() {
  input_file=$1
  output_file=$2

  shape=$(zenity --list --title "Dodawanie kształtów" --text "Wybierz rodzaj kształtu:" --radiolist --column "" --column "Kształt" FALSE "Prostokąt" FALSE "Okrąg" FALSE "Linia" FALSE "Trójkąt")

  if [ "$shape" == "Prostokąt" ]; then
    width=$(zenity --entry --title "Dodawanie kształtów" --text "Podaj szerokość prostokąta:")
    height=$(zenity --entry --title "Dodawanie kształtów" --text "Podaj wysokość prostokąta:")
    x=$(zenity --entry --title "Dodawanie kształtów" --text "Podaj współrzędną x:")
    y=$(zenity --entry --title "Dodawanie kształtów" --text "Podaj współrzędną y:")
    color=$(zenity --color-selection --title "Dodawanie kształtów" --text "Wybierz kolor prostokąta:")

    $convert_path "$input_file" -fill "$color" -stroke none -draw "rectangle $x,$y $((x+width)),$((y+height))" "$output_file"
  elif [ "$shape" == "Okrąg" ]; then
    radius=$(zenity --entry --title "Dodawanie kształtów" --text "Podaj promień okręgu:")
    x=$(zenity --entry --title "Dodawanie kształtów" --text "Podaj współrzędną x:")
    y=$(zenity --entry --title "Dodawanie kształtów" --text "Podaj współrzędną y:")
    color=$(zenity --color-selection --title "Dodawanie kształtów" --text "Wybierz kolor okręgu:")

    $convert_path "$input_file" -fill "$color" -stroke none -draw "circle $x,$y $((x+radius)),$((y+radius))" "$output_file"
  elif [ "$shape" == "Linia" ]; then
    x1=$(zenity --entry --title "Dodawanie kształtów" --text "Podaj współrzędną x początku linii:")
    y1=$(zenity --entry --title "Dodawanie kształtów" --text "Podaj współrzędną y początku linii:")
    x2=$(zenity --entry --title "Dodawanie kształtów" --text "Podaj współrzędną x końca linii:")
    y2=$(zenity --entry --title "Dodawanie kształtów" --text "Podaj współrzędną y końca linii:")
    color=$(zenity --color-selection --title "Dodawanie kształtów" --text "Wybierz kolor linii:")

    $convert_path "$input_file" -fill "$color" -stroke "$color" -draw "line $x1,$y1 $x2,$y2" "$output_file"
  elif [ "$shape" == "Trójkąt" ]; then
    x1=$(zenity --entry --title "Dodawanie kształtów" --text "Podaj współrzędną x pierwszego wierzchołka:")
    y1=$(zenity --entry --title "Dodawanie kształtów" --text "Podaj współrzędną y pierwszego wierzchołka:")
    x2=$(zenity --entry --title "Dodawanie kształtów" --text "Podaj współrzędną x drugiego wierzchołka:")
    y2=$(zenity --entry --title "Dodawanie kształtów" --text "Podaj współrzędną y drugiego wierzchołka:")
    x3=$(zenity --entry --title "Dodawanie kształtów" --text "Podaj współrzędną x trzeciego wierzchołka:")
    y3=$(zenity --entry --title "Dodawanie kształtów" --text "Podaj współrzędną y trzeciego wierzchołka:")
    color=$(zenity --color-selection --title "Dodawanie kształtów" --text "Wybierz kolor trójkąta:")

    $convert_path "$input_file" -fill "$color" -stroke none -draw "polygon $x1,$y1 $x2,$y2 $x3,$y3" "$output_file"
  fi

  zenity --info --title="Sukces" --text="Kształt został dodany do obrazu."
}
# Funkcja dodająca prostą ramkę
add_simple_frame() {
  input_file=$1
  output_file=$2

  frame_width=$(zenity --entry --title "Dodawanie ramki" --text "Podaj szerokość ramki:")
  color=$(zenity --color-selection --title "Dodawanie ramki" --text "Wybierz kolor ramki:")

  $convert_path "$input_file" -bordercolor "$color" -border $frame_width "$output_file"

  zenity --info --title="Sukces" --text="Prosta ramka została dodana do obrazu."
}

# Funkcja dodająca ozdobną ramkę
add_decorative_frame() {
  input_file=$1
  output_file=$2

  frame_width=$(zenity --entry --title "Dodawanie ramki" --text "Podaj szerokość ramki:")
  corner_radius=$(zenity --entry --title "Dodawanie ramki" --text "Podaj promień zaokrąglenia rogów:")
  color=$(zenity --color-selection --title "Dodawanie ramki" --text "Wybierz kolor ramki:")
  background_color=$(zenity --color-selection --title "Dodawanie ramki" --text "Wybierz kolor tła:")

  # Pobierz wymiary obrazu
  image_width=$(identify -format "%w" "$input_file")
  image_height=$(identify -format "%h" "$input_file")

  # Utwórz nowy obraz o rozszerzonych wymiarach dla ramki
  new_width=$((image_width + 2 * frame_width))
  new_height=$((image_height + 2 * frame_width))

  # Utwórz tło o podanym kolorze
  convert -size "${new_width}x${new_height}" xc:"$background_color" temp.png

  # Dodaj prostokątną ramkę na tle
  mogrify -path . -background none -fill none -stroke "$color" -strokewidth "$frame_width" -draw "roundrectangle $frame_width,$frame_width $((new_width-frame_width)),$((new_height-frame_width)) $corner_radius,$corner_radius" temp.png

  # Dodaj kółka w rogach ramki
  mogrify -path . -background none -fill "$color" -stroke none -draw "circle $frame_width,$frame_width $((frame_width+corner_radius)),$((frame_width+corner_radius))" temp.png
  mogrify -path . -background none -fill "$color" -stroke none -draw "circle $((new_width-frame_width)),$frame_width $((new_width-frame_width-corner_radius)),$((frame_width+corner_radius))" temp.png
  mogrify -path . -background none -fill "$color" -stroke none -draw "circle $frame_width,$((new_height-frame_width)) $((frame_width+corner_radius)),$((new_height-frame_width-corner_radius))" temp.png
  mogrify -path . -background none -fill "$color" -stroke none -draw "circle $((new_width-frame_width)),$((new_height-frame_width)) $((new_width-frame_width-corner_radius)),$((new_height-frame_width-corner_radius))" temp.png

  # Nałóż obraz wejściowy na ramkę
  composite -gravity center "$input_file" temp.png "$output_file"

  # Usuń tymczasowy plik
  rm temp.png

  zenity --info --title="Sukces" --text="Ozdobna ramka została dodana do obrazu."
}


# Funkcja dodająca ramkę
add_frame() {
  input_file=$1
  output_file=$2

  frame_type=$(zenity --list --title "Dodawanie ramki" --text "Wybierz typ ramki:" --radiolist --column "" --column "Typ" FALSE "Prosta" FALSE "Ozdobna")

  case $frame_type in
    "Prosta")
      add_simple_frame "$input_file" "$output_file"
      ;;
    "Ozdobna")
    	add_decorative_frame "$input_file" "$output_file"
      ;;
      *)
      echo "Nieznany typ ramki."
      exit 1
      ;;
  esac
  zenity --info --title="Sukces" --text="Ramka została dodana do obrazu."
}
#Mozaika
apply_mosaic_effect() {
  input_file=$1
  output_file=$2

  scale_factor=$(zenity --scale --title "Efekt mozaiki" --text "Wybierz stopień efektu mozaiki:" --min-value 2 --max-value 100 --value 10)

  $convert_path "$input_file" -scale $((100 / scale_factor))% -scale $((100 * scale_factor))% "$output_file"

  zenity --info --title="Sukces" --text="Efekt mozaiki został zastosowany."
}
#jasnosc
change_brightness() {
  input_file=$1
  output_file=$2

  brightness=$(zenity --scale --title "Zmiana jasności" --text "Wybierz wartość jasności:" --min-value -100 --max-value 100 --value 0)

  $convert_path "$input_file" -brightness-contrast $brightness "$output_file"

  zenity --info --title="Sukces" --text="Jasność obrazu została zmieniona."
}
# Dodawanie filtrow 
add_artistic_filter() {
  input_file=$1
  output_file=$2

  filter=$(zenity --list --title "Dodawanie filtrów" --text "Wybierz filtr:" --radiolist --column "" --column "Filtr" FALSE "Sketch" FALSE "Oil Paint")

  case $filter in
    "Sketch")
      $convert_path "$input_file" -sketch 0x10+120 "$output_file"
      ;;
    "Oil Paint")
      $convert_path "$input_file" -paint 4 "$output_file"
      ;;
    *)
      echo "Nieprawidłowy wybór filtru."
      exit 1
      ;;
  esac

  echo "Filtr artystyczny został zastosowany. Zapisano jako: $output_file"
}
zenity --info --title="Witaj!" --text="Witaj w aplikacji do edycji obrazów!\n\nMożesz używać różnych funkcji, takich jak: zamiana na czarno-biały, skalowanie, dodawanie blur, dodawanie tekstu, zmiana typu obrazu, obrót, dodawanie kształtów oraz dodawanie ramki.\n\nWybierz jedną z opcji z menu, aby rozpocząć edycję obrazu."
# Główne menu
main_menu() {
  options=(
    "Zamień na czarno-białe"
    "Skaluj obraz"
    "Dodaj blur"
    "Dodaj tekst"
    "Zmień typ obrazu"
    "Obróć obraz"
    "Dodaj kształty"
    "Dodaj ramke"
    "Zmiana jasnosci"
    "Mozaika"
    "Filtry"

    "Wyjście"
  )

  choice=$(zenity --list --title "Główne menu" --text "Wybierz opcję:" --column "Opcje" "${options[@]}" --width=500 --height=500)

  case $choice in
    "Zamień na czarno-białe")
      input_image=$(zenity --file-selection --title "Wybierz obraz wejściowy")
      output_image=$(zenity --file-selection --title "Wybierz miejsce zapisu obrazu wyjściowego" --save --confirm-overwrite)
      convert_to_black_and_white "$input_image" "$output_image"
      main_menu
      ;;
    "Skaluj obraz")
      input_image=$(zenity --file-selection --title "Wybierz obraz wejściowy")
      output_image=$(zenity --file-selection --title "Wybierz miejsce zapisu obrazu wyjściowego" --save --confirm-overwrite)
      scale_image "$input_image" "$output_image"
      main_menu
      ;;
    "Dodaj blur")
      input_image=$(zenity --file-selection --title "Wybierz obraz wejściowy")
      output_image=$(zenity --file-selection --title "Wybierz miejsce zapisu obrazu wyjściowego" --save --confirm-overwrite)
      add_blur "$input_image" "$output_image"
      main_menu
      ;;
    "Dodaj tekst")
      input_image=$(zenity --file-selection --title "Wybierz obraz wejściowy")
      output_image=$(zenity --file-selection --title "Wybierz miejsce zapisu obrazu wyjściowego" --save --confirm-overwrite)
      add_text "$input_image" "$output_image"
      main_menu
      ;;
    "Zmień typ obrazu")
      input_image=$(zenity --file-selection --title "Wybierz obraz wejściowy")
      output_image=$(zenity --file-selection --title "Wybierz miejsce zapisu obrazu wyjściowego" --save --confirm-overwrite)
      change_image_type "$input_image" "$output_image"
      main_menu
      ;;
    "Obróć obraz")
      input_image=$(zenity --file-selection --title "Wybierz obraz wejściowy")
      output_image=$(zenity --file-selection --title "Wybierz miejsce zapisu obrazu wyjściowego" --save --confirm-overwrite)
      rotate_image "$input_image" "$output_image"
      main_menu
      ;;
    "Dodaj kształty")
      input_image=$(zenity --file-selection --title "Wybierz obraz wejściowy")
      output_image=$(zenity --file-selection --title "Wybierz miejsce zapisu obrazu wyjściowego" --save --confirm-overwrite)
      add_shapes "$input_image" "$output_image"
      main_menu
      ;;
      "Dodaj ramke")
      input_image=$(zenity --file-selection --title "Wybierz obraz wejściowy")
      output_image=$(zenity --file-selection --title "Wybierz miejsce zapisu obrazu wyjściowego" --save --confirm-overwrite)
      add_frame "$input_image" "$output_image"
      main_menu
      ;;
      "Mozaika")
      input_image=$(zenity --file-selection --title "Wybierz obraz wejściowy")
      output_image=$(zenity --file-selection --title "Wybierz miejsce zapisu obrazu wyjściowego" --save --confirm-overwrite)
      apply_mosaic_effect "$input_image" "$output_image"
      main_menu
      ;;
      "Zmiana jasnosci")
      input_image=$(zenity --file-selection --title "Wybierz obraz wejściowy")
      output_image=$(zenity --file-selection --title "Wybierz miejsce zapisu obrazu wyjściowego" --save --confirm-overwrite)
      change_brightness "$input_image" "$output_image"
      main_menu
      ;;
      "Filtry")
      input_image=$(zenity --file-selection --title "Wybierz obraz wejściowy")
      output_image=$(zenity --file-selection --title "Wybierz miejsce zapisu obrazu wyjściowego" --save --confirm-overwrite)
      add_artistic_filter "$input_image" "$output_image"
      main_menu
      ;;

    "Wyjście")
      exit 0
      ;;
    *)
      zenity --error --title="Błąd" --text="Nieprawidłowa opcja. Wybierz ponownie."
      main_menu
      ;;
  esac
}

# Uruchomienie głównego menu
main_menu
