//
//  SpanishConversations.swift
//  ReaderFeature
//
//  Bundled starter dialogues in Mexican Spanish (es-MX), each line paired
//  with an English translation. Plain Swift data rather than a resource file
//  so the content is type-checked and needs no bundle lookup.
//

extension Conversation {
    static let spanish: [Conversation] = [
        Conversation(
            id: "es-meeting",
            title: "Mucho gusto",
            englishTitle: "Meeting someone",
            symbol: "hand.wave",
            level: .beginner,
            speakers: [
                .init(name: "Ana", gender: .female),
                .init(name: "Luis", gender: .male),
            ],
            lines: [
                .init(0, "¡Hola! ¿Cómo te llamas?", "Hi! What's your name?"),
                .init(1, "Hola, me llamo Luis. ¿Y tú?", "Hi, my name is Luis. And you?"),
                .init(0, "Me llamo Ana. Mucho gusto.", "My name is Ana. Nice to meet you."),
                .init(1, "Igualmente. ¿De dónde eres?", "Likewise. Where are you from?"),
                .init(0, "Soy de Guadalajara. ¿Y tú?", "I'm from Guadalajara. And you?"),
                .init(1, "Yo soy de aquí, de la Ciudad de México.", "I'm from here, from Mexico City."),
                .init(0, "¡Qué padre! Me encanta esta ciudad.", "How cool! I love this city."),
                .init(1, "Bienvenida. Nos vemos pronto.", "Welcome. See you soon."),
            ]
        ),
        Conversation(
            id: "es-cafe",
            title: "En la cafetería",
            englishTitle: "At the coffee shop",
            symbol: "cup.and.saucer",
            level: .beginner,
            speakers: [
                .init(name: "Barista", gender: .male),
                .init(name: "Sofía", gender: .female),
            ],
            lines: [
                .init(0, "Buenos días. ¿Qué le sirvo?", "Good morning. What can I get you?"),
                .init(1, "Buenos días. ¿Me da un café con leche, por favor?", "Good morning. Can I have a coffee with milk, please?"),
                .init(0, "¿Chico, mediano o grande?", "Small, medium or large?"),
                .init(1, "Mediano, por favor. Y un pan dulce.", "Medium, please. And a sweet bread."),
                .init(0, "¿Es para aquí o para llevar?", "Is it for here or to go?"),
                .init(1, "Para llevar. ¿Cuánto es?", "To go. How much is it?"),
                .init(0, "Son ochenta y cinco pesos.", "That's eighty-five pesos."),
                .init(1, "Aquí tiene. Gracias.", "Here you go. Thank you."),
                .init(0, "A usted. ¡Que tenga buen día!", "Thank you. Have a nice day!"),
            ]
        ),
        Conversation(
            id: "es-directions",
            title: "¿Dónde está el metro?",
            englishTitle: "Asking for directions",
            symbol: "map",
            level: .beginner,
            speakers: [
                .init(name: "Turista", gender: .female),
                .init(name: "Señor", gender: .male),
            ],
            lines: [
                .init(0, "Disculpe, ¿dónde está la estación del metro?", "Excuse me, where is the subway station?"),
                .init(1, "Está a dos cuadras. Siga derecho por esta calle.", "It's two blocks away. Go straight down this street."),
                .init(0, "¿Y luego?", "And then?"),
                .init(1, "En el semáforo, dé vuelta a la izquierda.", "At the traffic light, turn left."),
                .init(0, "¿Está lejos?", "Is it far?"),
                .init(1, "No, está muy cerca. Son como cinco minutos caminando.", "No, it's very close. It's about five minutes walking."),
                .init(0, "Muchas gracias, muy amable.", "Thank you very much, that's very kind."),
                .init(1, "De nada. Que le vaya bien.", "You're welcome. Take care."),
            ]
        ),
        Conversation(
            id: "es-tacos",
            title: "En la taquería",
            englishTitle: "At the taco stand",
            symbol: "fork.knife",
            level: .beginner,
            speakers: [
                .init(name: "Taquero", gender: .male),
                .init(name: "Mariana", gender: .female),
            ],
            lines: [
                .init(0, "¿Qué va a querer, güera?", "What would you like?"),
                .init(1, "Me da cuatro tacos al pastor, por favor.", "Can I have four al pastor tacos, please."),
                .init(0, "¿Con todo?", "With everything?"),
                .init(1, "Sí, con cebolla y cilantro, pero sin piña.", "Yes, with onion and cilantro, but no pineapple."),
                .init(0, "¿Y de tomar?", "And to drink?"),
                .init(1, "Un agua de horchata, por favor.", "A horchata, please."),
                .init(0, "¿La salsa verde o la roja?", "The green salsa or the red one?"),
                .init(1, "La verde. ¿Pica mucho?", "The green one. Is it very spicy?"),
                .init(0, "Pica poquito nomás.", "It's just a little spicy."),
            ]
        ),
        Conversation(
            id: "es-market",
            title: "En el mercado",
            englishTitle: "At the market",
            symbol: "basket",
            level: .beginner,
            speakers: [
                .init(name: "Doña Rosa", gender: .female),
                .init(name: "Diego", gender: .male),
            ],
            lines: [
                .init(0, "¿Qué le damos, joven?", "What can we get you, young man?"),
                .init(1, "¿A cómo están los aguacates?", "How much are the avocados?"),
                .init(0, "A cuarenta pesos el kilo.", "Forty pesos per kilo."),
                .init(1, "Deme un kilo, por favor. Que estén maduros.", "Give me a kilo, please. Ripe ones."),
                .init(0, "Claro. ¿Algo más?", "Of course. Anything else?"),
                .init(1, "Sí, medio kilo de jitomates y unos limones.", "Yes, half a kilo of tomatoes and some limes."),
                .init(0, "Son setenta pesos en total.", "That's seventy pesos in total."),
                .init(1, "¿Me deja todo en sesenta?", "Would you let me have it all for sixty?"),
                .init(0, "Ándele, pues. Por ser usted.", "Alright then. Just for you."),
            ]
        ),
        Conversation(
            id: "es-taxi",
            title: "Tomando un taxi",
            englishTitle: "Taking a taxi",
            symbol: "car",
            level: .beginner,
            speakers: [
                .init(name: "Pasajera", gender: .female),
                .init(name: "Taxista", gender: .male),
            ],
            lines: [
                .init(0, "Buenas tardes. ¿Me lleva al aeropuerto?", "Good afternoon. Can you take me to the airport?"),
                .init(1, "Sí, cómo no. Súbase.", "Yes, of course. Get in."),
                .init(0, "¿Cuánto tiempo hacemos?", "How long will it take?"),
                .init(1, "Con este tráfico, como cuarenta minutos.", "With this traffic, about forty minutes."),
                .init(0, "Uy, tengo un poco de prisa. Mi vuelo sale a las seis.", "Oh, I'm in a bit of a hurry. My flight leaves at six."),
                .init(1, "No se preocupe, me voy por otro lado.", "Don't worry, I'll take another route."),
                .init(0, "¿Acepta tarjeta?", "Do you take card?"),
                .init(1, "No, nada más efectivo, señorita.", "No, cash only, miss."),
            ]
        ),
        Conversation(
            id: "es-hotel",
            title: "En el hotel",
            englishTitle: "Checking into a hotel",
            symbol: "bed.double",
            level: .intermediate,
            speakers: [
                .init(name: "Recepcionista", gender: .female),
                .init(name: "Carlos", gender: .male),
            ],
            lines: [
                .init(0, "Bienvenido. ¿En qué le puedo ayudar?", "Welcome. How can I help you?"),
                .init(1, "Tengo una reservación a nombre de Carlos Méndez.", "I have a reservation under the name Carlos Méndez."),
                .init(0, "Sí, aquí está. Tres noches, habitación doble. ¿Me permite una identificación?", "Yes, here it is. Three nights, double room. May I see some ID?"),
                .init(1, "Claro, aquí tiene mi pasaporte.", "Sure, here's my passport."),
                .init(0, "Gracias. El desayuno se sirve de siete a once en el restaurante.", "Thank you. Breakfast is served from seven to eleven in the restaurant."),
                .init(1, "Perfecto. ¿Cuál es la contraseña del wifi?", "Perfect. What's the wifi password?"),
                .init(0, "Viene en la tarjeta de su llave. Su habitación es la cuatrocientos doce.", "It's on your key card. Your room is four twelve."),
                .init(1, "Muchas gracias. ¿A qué hora es la salida?", "Thank you very much. What time is check-out?"),
                .init(0, "A las doce del día. Que disfrute su estancia.", "At noon. Enjoy your stay."),
            ]
        ),
        Conversation(
            id: "es-plans",
            title: "Planes para el fin de semana",
            englishTitle: "Weekend plans",
            symbol: "calendar",
            level: .intermediate,
            speakers: [
                .init(name: "Valeria", gender: .female),
                .init(name: "Javier", gender: .male),
            ],
            lines: [
                .init(0, "¿Qué onda? ¿Qué vas a hacer este fin de semana?", "What's up? What are you doing this weekend?"),
                .init(1, "Todavía no sé. ¿Tienes algún plan?", "I don't know yet. Do you have any plans?"),
                .init(0, "Unos amigos y yo vamos a ir a Xochimilco el sábado. ¿Te late?", "Some friends and I are going to Xochimilco on Saturday. Are you in?"),
                .init(1, "¡Me late! ¿A qué hora nos vemos?", "I'm in! What time should we meet?"),
                .init(0, "Como a las diez, en la estación de Tasqueña.", "Around ten, at Tasqueña station."),
                .init(1, "Va. ¿Llevo algo?", "Okay. Should I bring anything?"),
                .init(0, "Si quieres, lleva algo de botanas. Nosotros llevamos las bebidas.", "If you want, bring some snacks. We'll bring the drinks."),
                .init(1, "Sale. Ahí nos vemos.", "Deal. See you there."),
            ]
        ),
        Conversation(
            id: "es-pharmacy",
            title: "En la farmacia",
            englishTitle: "At the pharmacy",
            symbol: "cross.case",
            level: .intermediate,
            speakers: [
                .init(name: "Farmacéutico", gender: .male),
                .init(name: "Lucía", gender: .female),
            ],
            lines: [
                .init(0, "Buenas noches. ¿Qué necesita?", "Good evening. What do you need?"),
                .init(1, "Me duele mucho la cabeza y creo que tengo fiebre.", "I have a bad headache and I think I have a fever."),
                .init(0, "¿Desde cuándo se siente así?", "Since when have you felt like this?"),
                .init(1, "Desde ayer en la noche.", "Since last night."),
                .init(0, "Le recomiendo este paracetamol. Tome una pastilla cada ocho horas.", "I recommend this paracetamol. Take one pill every eight hours."),
                .init(1, "¿Lo puedo tomar con el estómago vacío?", "Can I take it on an empty stomach?"),
                .init(0, "Mejor después de comer. Y tome muchos líquidos.", "Better after eating. And drink lots of fluids."),
                .init(1, "Gracias. Si no se me quita, voy al doctor.", "Thanks. If it doesn't go away, I'll see a doctor."),
                .init(0, "Así es. Que se mejore.", "That's right. Get well soon."),
            ]
        ),
        Conversation(
            id: "es-phone",
            title: "Una llamada",
            englishTitle: "A phone call",
            symbol: "phone",
            level: .intermediate,
            speakers: [
                .init(name: "Mamá", gender: .female),
                .init(name: "Andrés", gender: .male),
            ],
            lines: [
                .init(1, "¿Bueno?", "Hello?"),
                .init(0, "Hola, mijo. ¿Cómo estás?", "Hi, son. How are you?"),
                .init(1, "Bien, mamá. Aquí trabajando. ¿Y tú?", "Good, Mom. Just working. And you?"),
                .init(0, "Bien. Oye, ¿vas a venir a comer el domingo?", "Good. Hey, are you coming over for lunch on Sunday?"),
                .init(1, "Sí, pero voy a llegar un poco tarde.", "Yes, but I'm going to arrive a little late."),
                .init(0, "No hay problema. Voy a hacer mole.", "No problem. I'm going to make mole."),
                .init(1, "¡Qué rico! Ahorita te marco más tarde, ¿sí?", "Delicious! I'll call you back later, okay?"),
                .init(0, "Sí, mijo. Cuídate mucho.", "Yes, son. Take good care of yourself."),
            ]
        ),
    ]
}
