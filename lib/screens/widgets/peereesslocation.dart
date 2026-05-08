import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/peereesscompanyprovider.dart';
import 'package:provider/provider.dart';
import 'package:peereess/model/peereess.dart';

class Peereesslocation extends StatefulWidget {
  final Function(Peereess pickup) onPickupSelected;

  const Peereesslocation({super.key, required this.onPickupSelected});

  @override
  State<Peereesslocation> createState() => _PeereesslocationState();
}

class _PeereesslocationState extends State<Peereesslocation> {
  String selectedRegion = "Lagos";
  String selectedCity = "Ikeja";
  String? selectedPickupId;

  static const Map<String, List<String>> nigeria = {
    "Abia": [
      "Umuahia",
      "Aba",
      "Ohafia",
      "Arochukwu",
      "Bende",
      "Ugwunagbo",
      "Isuikwuato",
      "Ukwa East",
      "Ukwa West",
      "Ikwuano",
    ],
    "Adamawa": [
      "Yola",
      "Mubi",
      "Numan",
      "Ganye",
      "Maiha",
      "Michika",
      "Hong",
      "Gombi",
      "Fufore",
      "Demsa",
    ],
    "Akwa Ibom": [
      "Uyo",
      "Eket",
      "Ikot Ekpene",
      "Abak",
      "Oron",
      "Etinan",
      "Essien Udim",
      "Ukanafun",
      "Ibeno",
      "Onna",
    ],
    "Anambra": [
      "Awka",
      "Onitsha",
      "Nnewi",
      "Ekwulobia",
      "Okija",
      "Aguata",
      "Orumba",
      "Idemili",
      "Ayamelum",
      "Ogbaru",
    ],
    "Bauchi": [
      "Bauchi",
      "Azare",
      "Misau",
      "Ningi",
      "Katagum",
      "Gamawa",
      "Alkaleri",
      "Toro",
      "Damban",
      "Shira",
    ],
    "Bayelsa": [
      "Yenagoa",
      "Ogbia",
      "Sagbama",
      "Brass",
      "Nembe",
      "Kolokuma/Opokuma",
      "Ekeremor",
      "Southern Ijaw",
      "Nembe Town",
      "Amassoma",
    ],
    "Benue": [
      "Makurdi",
      "Gboko",
      "Otukpo",
      "Vandeikya",
      "Tarka",
      "Ukum",
      "Guma",
      "Logo",
      "Konshisha",
      "Oju",
    ],
    "Borno": [
      "Maiduguri",
      "Biu",
      "Dikwa",
      "Bama",
      "Gwoza",
      "Gubio",
      "Kaga",
      "Hawul",
      "Monguno",
      "Kwaya Kusar",
    ],
    "Cross River": [
      "Calabar",
      "Ikom",
      "Ogoja",
      "Obudu",
      "Bekwarra",
      "Boki",
      "Akpabuyo",
      "Bakassi",
      "Biase",
      "Etung",
    ],
    "Delta": [
      "Asaba",
      "Warri",
      "Sapele",
      "Ughelli",
      "Ozoro",
      "Effurun",
      "Agbor",
      "Kwale",
      "Oleh",
      "Abraka",
    ],
    "Ebonyi": [
      "Abakaliki",
      "Afikpo",
      "Onueke",
      "Izzi",
      "Ezza",
      "Ohaukwu",
      "Ikwo",
      "Ebonyi",
      "Ohaozara",
      "Afikpo North",
    ],
    "Edo": [
      "Benin City",
      "Auchi",
      "Ekpoma",
      "Igarra",
      "Irrua",
      "Uromi",
      "Okpella",
      "Fugar",
      "Owan",
      "Oredo",
    ],
    "Ekiti": [
      "Ado-Ekiti",
      "Ikere",
      "Ise",
      "Efon",
      "Oye",
      "Ikole",
      "Ijero",
      "Gbonyin",
      "Emure",
      "Moba",
    ],
    "Enugu": [
      "Enugu",
      "Nsukka",
      "Awgu",
      "Oji River",
      "Igbo-Eze",
      "Udi",
      "Nkanu",
      "Aninri",
      "Ezeagu",
      "Isi-Uzo",
    ],
    "Gombe": [
      "Gombe",
      "Kaltungo",
      "Billiri",
      "Yamaltu",
      "Deba",
      "Akko",
      "Balanga",
      "Funakaye",
      "Nafada",
      "Dukku",
    ],
    "Imo": [
      "Owerri",
      "Orlu",
      "Okigwe",
      "Oguta",
      "Ohaji/Egbema",
      "Ngor Okpala",
      "Mbaitoli",
      "Njaba",
      "Nkwerre",
      "Ideato",
    ],
    "Jigawa": [
      "Dutse",
      "Hadejia",
      "Gumel",
      "Kazaure",
      "Birni Kudu",
      "Ringim",
      "Kaugama",
      "Babura",
      "Sule-Tankarkar",
      "Malam Madori",
    ],
    "Kaduna": [
      "Kaduna",
      "Zaria",
      "Kafanchan",
      "Giwa",
      "Jema'a",
      "Soba",
      "Sabon Gari",
      "Kaura",
      "Kachia",
      "Chikun",
    ],
    "Kano": [
      "Kano",
      "Wudil",
      "Rano",
      "Gaya",
      "Bichi",
      "Gwale",
      "Gezawa",
      "Dala",
      "Tudun Wada",
      "Kunchi",
    ],
    "Katsina": [
      "Katsina",
      "Daura",
      "Funtua",
      "Malumfashi",
      "Bakori",
      "Kankia",
      "Dutsin-Ma",
      "Jibia",
      "Mashi",
      "Musawa",
    ],
    "Kebbi": [
      "Birnin Kebbi",
      "Argungu",
      "Yauri",
      "Zuru",
      "Ngaski",
      "Aliero",
      "Sakaba",
      "Arewa Dandi",
      "Gwandu",
      "Shanga",
    ],
    "Kogi": [
      "Lokoja",
      "Okene",
      "Idah",
      "Ajaokuta",
      "Bassa",
      "Dekina",
      "Ankpa",
      "Mopa",
      "Ogori",
      "Igalamela",
    ],
    "Kwara": [
      "Ilorin",
      "Offa",
      "Omu-Aran",
      "Edu",
      "Kaiama",
      "Baruten",
      "Patigi",
      "Lafiagi",
      "Jebba",
      "Kaiama",
    ],
    "Lagos": [
      "Ikeja",
      "Lekki",
      "Surulere",
      "Yaba",
      "Ikorodu",
      "Ajah",
      "Victoria Island",
      "Apapa",
      "Festac",
      "Mushin",
    ],
    "Nasarawa": [
      "Lafia",
      "Keffi",
      "Akwanga",
      "Karshi",
      "Doma",
      "Toto",
      "Nasarawa",
      "Kokona",
      "Karu",
      "Wamba",
    ],
    "Niger": [
      "Minna",
      "Bida",
      "Suleja",
      "Kontagora",
      "Lokoja",
      "Shiroro",
      "Borgu",
      "Rafi",
      "Wushishi",
      "Chanchaga",
    ],
    "Ogun": [
      "Abeokuta",
      "Ijebu-Ode",
      "Sagamu",
      "Ijebu Igbo",
      "Ota",
      "Sango Ota",
      "Agbara",
      "Ijebu North",
      "Ilaro",
      "Odogbolu",
    ],
    "Ondo": [
      "Akure",
      "Owo",
      "Ondo",
      "Ikare",
      "Okitipupa",
      "Ifon",
      "Ile-Oluji",
      "Odigbo",
      "Idanre",
      "Irele",
    ],
    "Osun": [
      "Oshogbo",
      "Ife",
      "Ilesa",
      "Ede",
      "Iwo",
      "Ikirun",
      "Gbongan",
      "Ejigbo",
      "Ayedaade",
      "Ilesha West",
    ],
    "Oyo": [
      "Ibadan",
      "Ogbomosho",
      "Oyo",
      "Saki",
      "Iseyin",
      "Ogbomoso North",
      "Ogbomoso South",
      "Eruwa",
      "Ibarapa",
      "Olorunsogo",
    ],
    "Plateau": [
      "Jos",
      "Bukuru",
      "Shendam",
      "Pankshin",
      "Langtang",
      "Bokkos",
      "Mangu",
      "Barkin Ladi",
      "Kanke",
      "Riyom",
    ],
    "Rivers": [
      "Port Harcourt",
      "Bonny",
      "Ahoada",
      "Bori",
      "Degema",
      "Eleme",
      "Emohua",
      "Opobo",
      "Okrika",
      "Obio-Akpor",
    ],
    "Sokoto": [
      "Sokoto",
      "Tambuwal",
      "Wurno",
      "Gwadabawa",
      "Dange Shuni",
      "Binji",
      "Kebbe",
      "Gada",
      "Illela",
      "Shagari",
    ],
    "Taraba": [
      "Jalingo",
      "Wukari",
      "Bali",
      "Ibi",
      "Takum",
      "Donga",
      "Ussa",
      "K/Lamurde",
      "Yorro",
      "Gashaka",
    ],
    "Yobe": [
      "Damaturu",
      "Potiskum",
      "Gashua",
      "Bade",
      "Geidam",
      "Fika",
      "Fune",
      "Jakusko",
      "Karasuwa",
      "Nguru",
    ],
    "Zamfara": [
      "Gusau",
      "Kaura Namoda",
      "Anka",
      "Bukkuyum",
      "Talata Mafara",
      "Maradun",
      "Maru",
      "Shinkafi",
      "Bakura",
      "Birnin Magaji",
    ],
    "Abuja": [
      "Garki",
      "Wuse",
      "Maitama",
      "Asokoro",
      "Kubwa",
      "Jabi",
      "Gwarinpa",
      "Lokogoma",
      "Karshi",
      "Utako",
    ],
  };

  List<Peereess> get pickupsForSelectedCity {
    final provider = context.read<PeereessProvider>();
    return provider.peereessList
        .where((p) => p.region == selectedRegion && p.city == selectedCity)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    // Safe fetch after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PeereessProvider>();
      provider.fetchPeereess();
    });
  }

  void _selectPickup(Peereess pickup) {
    setState(() {
      selectedPickupId = pickup.id;
    });
    widget.onPickupSelected(pickup); // notify parent
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PeereessProvider>();
    final cities = nigeria[selectedRegion]!;
    final formatter = NumberFormat("#,##0", "en_US");

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              // Region Dropdown
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: DropdownButtonFormField<String>(
                    value: selectedRegion,
                    isExpanded: true,
                    items: nigeria.keys
                        .map(
                          (region) => DropdownMenuItem(
                            value: region,
                            child: Text(
                              region,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xff9D6E2D),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedRegion = value;
                        selectedCity = nigeria[value]!.first;
                        selectedPickupId = null;
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(255, 231, 199, 209),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    dropdownColor: Colors.white,
                  ),
                ),
              ),
              20.getWidthWhiteSpacing,
              // City Dropdown
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: DropdownButtonFormField<String>(
                    value: selectedCity,
                    isExpanded: true,
                    items: cities
                        .map(
                          (city) => DropdownMenuItem(
                            value: city,
                            child: Text(
                              city,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xff9D6E2D),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedCity = value;
                        selectedPickupId = null;
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(255, 231, 199, 209),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    dropdownColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          20.getHeightWhiteSpacing,
          provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : pickupsForSelectedCity.isEmpty
                  ? const Text("No pickup station found for selected city")
                  : Column(
                      children: pickupsForSelectedCity.map((pickup) {
                        final isSelectedPickup = pickup.id == selectedPickupId;
                        return GestureDetector(
                          onTap: () => _selectPickup(pickup),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                              color: isSelectedPickup
                                  ? Colors.amber.withOpacity(0.3)
                                  : Colors.white,
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      height: 15,
                                      width: 15,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.grey),
                                      ),
                                      child: isSelectedPickup
                                          ? const Padding(
                                              padding: EdgeInsets.all(2.0),
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xff9D6E2D),
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    5.getWidthWhiteSpacing,
                                    Text(
                                      pickup.pickupstation,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      "₦${formatter.format(pickup.fee)}",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                Text(
                                  pickup.address,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                Text(
                                  pickup.phoneNumber,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
        ],
      ),
    );
  }
}
