//
//  SpanishFoodConversations.swift
//  ReaderFeature
//
//  Intermediate dialogues about restaurants, food and ordering, in Mexican
//  Spanish — usted with staff, preterite/imperfect, polite requests with
//  quisiera/podría, and the vocabulary of menus, bills and complaints.
//

extension Conversation {
    static let spanishFood: [Conversation] = [
        Conversation(
            id: "es-food-reservation",
            title: "Reservando una mesa",
            englishTitle: "Booking a table",
            symbol: "phone.badge.checkmark",
            level: .intermediate,
            speakers: [
                .init(name: "Hostess", gender: .female),
                .init(name: "Tomás", gender: .male),
            ],
            lines: [
                .init(0, "Restaurante El Cardenal, buenas tardes. ¿En qué le puedo servir?", "El Cardenal restaurant, good afternoon. How can I help you?"),
                .init(1, "Buenas tardes. Quisiera reservar una mesa para el sábado en la noche.", "Good afternoon. I'd like to book a table for Saturday night."),
                .init(0, "Con gusto. ¿Para cuántas personas sería?", "Gladly. For how many people would it be?"),
                .init(1, "Para seis. Es el cumpleaños de mi papá.", "For six. It's my dad's birthday."),
                .init(0, "¡Qué bonito! Tengo disponible a las siete y media o a las nueve.", "How nice! I have seven thirty or nine available."),
                .init(1, "A las siete y media está perfecto. ¿Tienen terraza?", "Seven thirty is perfect. Do you have a terrace?"),
                .init(0, "Sí, pero en la terraza no podemos garantizar la mesa si llueve.", "Yes, but on the terrace we can't guarantee the table if it rains."),
                .init(1, "Entonces mejor adentro. ¿Podrían poner una vela en el postre?", "Then inside is better. Could you put a candle on the dessert?"),
                .init(0, "Claro que sí. ¿A nombre de quién la dejo?", "Of course. What name should I put it under?"),
                .init(1, "A nombre de Tomás Aguilar. Muchas gracias.", "Under Tomás Aguilar. Thank you very much."),
                .init(0, "Listo, quedó reservada. Le pedimos llegar con diez minutos de tolerancia.", "All set, it's booked. We ask that you arrive within ten minutes of the time."),
            ]
        ),
        Conversation(
            id: "es-food-ordering",
            title: "¿Qué me recomienda?",
            englishTitle: "What do you recommend?",
            symbol: "menucard",
            level: .intermediate,
            speakers: [
                .init(name: "Mesero", gender: .male),
                .init(name: "Camila", gender: .female),
            ],
            lines: [
                .init(0, "Buenas noches, ¿ya saben qué van a pedir o les doy unos minutos?", "Good evening, do you know what you'll order or should I give you a few minutes?"),
                .init(1, "Todavía no. ¿Qué me recomienda? Es la primera vez que venimos.", "Not yet. What do you recommend? It's our first time here."),
                .init(0, "La especialidad de la casa es la cochinita pibil. También el pescado a la talla está muy rico.", "The house specialty is cochinita pibil. The grilled fish is also really good."),
                .init(1, "¿La cochinita pica mucho?", "Is the cochinita very spicy?"),
                .init(0, "No, la cochinita no pica. Pica la salsa de habanero que viene aparte.", "No, the cochinita isn't spicy. The habanero salsa that comes on the side is."),
                .init(1, "Perfecto, entonces quiero la cochinita. ¿Con qué viene acompañada?", "Perfect, then I'll have the cochinita. What does it come with?"),
                .init(0, "Con frijoles colados, cebolla morada y tortillas hechas a mano.", "With strained beans, pickled red onion and handmade tortillas."),
                .init(1, "Suena delicioso. Y para empezar, ¿nos trae un guacamole al centro?", "Sounds delicious. And to start, could you bring us a guacamole to share?"),
                .init(0, "Con mucho gusto. ¿Y para tomar?", "With pleasure. And to drink?"),
                .init(1, "Una jarra de agua de jamaica, por favor.", "A pitcher of hibiscus water, please."),
                .init(0, "Enseguida se los traigo.", "I'll bring them right away."),
            ]
        ),
        Conversation(
            id: "es-food-fonda",
            title: "La comida corrida",
            englishTitle: "The set lunch",
            symbol: "takeoutbag.and.cup.and.straw",
            level: .intermediate,
            speakers: [
                .init(name: "Doña Lupe", gender: .female),
                .init(name: "Ricardo", gender: .male),
            ],
            lines: [
                .init(0, "Pásele, joven. Hoy tenemos comida corrida de ochenta y cinco pesos.", "Come in, young man. Today we have the set lunch for eighty-five pesos."),
                .init(1, "¿Qué incluye?", "What does it include?"),
                .init(0, "Sopa o consomé, arroz, un guisado, postre y agua del día.", "Soup or broth, rice, a main dish, dessert and the drink of the day."),
                .init(1, "¿Y qué guisados hay?", "And what main dishes are there?"),
                .init(0, "Hay pollo en mole, chiles rellenos y bistec a la mexicana.", "There's chicken in mole, stuffed chiles, and Mexican-style steak."),
                .init(1, "Ayer comí mole en casa de mi suegra, así que hoy los chiles rellenos.", "Yesterday I ate mole at my mother-in-law's, so today the stuffed chiles."),
                .init(0, "¿Los quiere de queso o de picadillo?", "Do you want them with cheese or ground meat?"),
                .init(1, "De queso. ¿Y de qué es el agua de hoy?", "Cheese. And what's today's drink?"),
                .init(0, "De horchata. Y de postre hay arroz con leche o gelatina.", "Horchata. And for dessert there's rice pudding or gelatin."),
                .init(1, "Arroz con leche, por favor. Usted sí cocina como en casa, doña Lupe.", "Rice pudding, please. You really cook like home, Doña Lupe."),
                .init(0, "Ay, gracias, mijo. Siéntese donde guste.", "Oh, thank you, dear. Sit wherever you like."),
            ]
        ),
        Conversation(
            id: "es-food-allergy",
            title: "Soy alérgica",
            englishTitle: "I'm allergic",
            symbol: "allergens",
            level: .intermediate,
            speakers: [
                .init(name: "Andrea", gender: .female),
                .init(name: "Mesero", gender: .male),
            ],
            lines: [
                .init(0, "Disculpe, antes de pedir, quería avisarle que soy alérgica a los cacahuates.", "Excuse me, before ordering, I wanted to let you know I'm allergic to peanuts."),
                .init(1, "Gracias por avisarnos. ¿Es una alergia fuerte?", "Thanks for telling us. Is it a severe allergy?"),
                .init(0, "Sí, bastante. Aunque sea un poquito, me hace daño.", "Yes, quite. Even a little bit makes me sick."),
                .init(1, "Entiendo. El mole y la salsa macha llevan cacahuate, así que esos no se los recomiendo.", "I understand. The mole and the salsa macha have peanuts, so I don't recommend those."),
                .init(0, "¿Y las enchiladas suizas?", "And the enchiladas suizas?"),
                .init(1, "Esas no llevan, pero déjeme confirmar con el cocinero que no usen el mismo aceite.", "Those don't have any, but let me confirm with the cook that they don't use the same oil."),
                .init(0, "Se lo agradezco mucho. Mi amigo es vegetariano, ¿tienen opciones sin carne?", "I really appreciate it. My friend is vegetarian, do you have meat-free options?"),
                .init(1, "Sí, tenemos tacos de hongos, chiles en nogada sin carne y una ensalada de nopales.", "Yes, we have mushroom tacos, meatless chiles en nogada and a cactus salad."),
                .init(0, "Perfecto. Esperamos a que nos confirme y ya pedimos.", "Perfect. We'll wait for you to confirm and then we'll order."),
                .init(1, "Ahorita regreso. No se preocupe, aquí la cuidamos.", "I'll be right back. Don't worry, we'll take care of you here."),
            ]
        ),
        Conversation(
            id: "es-food-complaint",
            title: "Un error en el pedido",
            englishTitle: "A mistake with the order",
            symbol: "exclamationmark.bubble",
            level: .intermediate,
            speakers: [
                .init(name: "Gabriela", gender: .female),
                .init(name: "Gerente", gender: .male),
            ],
            lines: [
                .init(0, "Disculpe, creo que hubo una confusión con mi platillo.", "Excuse me, I think there was a mix-up with my dish."),
                .init(1, "Lo siento mucho. ¿Qué fue lo que pidió?", "I'm very sorry. What did you order?"),
                .init(0, "Pedí los tacos de pescado, pero me trajeron de camarón.", "I ordered the fish tacos, but they brought me shrimp."),
                .init(1, "Tiene toda la razón, fue un error de la cocina. Ahorita se los cambio.", "You're absolutely right, it was a kitchen mistake. I'll change them for you right now."),
                .init(0, "Gracias. Además, la sopa estaba un poco fría.", "Thanks. Also, the soup was a little cold."),
                .init(1, "Qué pena con usted. ¿Quiere que se la calienten o prefiere otra cosa?", "I'm so sorry. Do you want it heated up or would you prefer something else?"),
                .init(0, "Si me la calientan está bien, no hay problema.", "If you heat it up that's fine, no problem."),
                .init(1, "Claro. Y para disculparnos, el postre corre por cuenta de la casa.", "Of course. And to apologize, dessert is on the house."),
                .init(0, "¡Qué amable! No era necesario, pero se lo agradezco.", "How kind! It wasn't necessary, but I appreciate it."),
                .init(1, "Al contrario, gracias por su paciencia. En cinco minutos le traigo sus tacos.", "On the contrary, thank you for your patience. I'll bring your tacos in five minutes."),
            ]
        ),
        Conversation(
            id: "es-food-bill",
            title: "La cuenta, por favor",
            englishTitle: "The check, please",
            symbol: "creditcard",
            level: .intermediate,
            speakers: [
                .init(name: "Sebastián", gender: .male),
                .init(name: "Paola", gender: .female),
            ],
            lines: [
                .init(0, "Joven, ¿nos trae la cuenta, por favor?", "Excuse me, could you bring us the check, please?"),
                .init(1, "¿Cómo la dividimos? ¿Cada quien lo suyo o a partes iguales?", "How should we split it? Everyone pays for their own, or equal parts?"),
                .init(0, "Mejor cada quien lo suyo, porque tú no tomaste nada de alcohol.", "Better each pays their own, because you didn't drink any alcohol."),
                .init(1, "Ok. Yo pedí la sopa de tortilla, las enchiladas y un agua de limón.", "Okay. I ordered the tortilla soup, the enchiladas and a limeade."),
                .init(0, "A ver... a ti te tocan doscientos treinta, y a mí trescientos diez.", "Let's see... yours comes to two hundred thirty, and mine three hundred ten."),
                .init(1, "¿La propina ya viene incluida?", "Is the tip already included?"),
                .init(0, "No, aquí no la incluyen. Normalmente se deja entre el diez y el quince por ciento.", "No, they don't include it here. You usually leave between ten and fifteen percent."),
                .init(1, "El servicio estuvo excelente, dejemos el quince.", "The service was excellent, let's leave fifteen."),
                .init(0, "De acuerdo. ¿Aceptan tarjeta o nada más efectivo?", "Agreed. Do they take cards or just cash?"),
                .init(1, "Aceptan tarjeta. Voy a pedir que nos traigan la terminal.", "They take cards. I'll ask them to bring us the card machine."),
            ]
        ),
        Conversation(
            id: "es-food-delivery",
            title: "Comida a domicilio",
            englishTitle: "Ordering delivery",
            symbol: "bicycle",
            level: .intermediate,
            speakers: [
                .init(name: "Pizzería", gender: .male),
                .init(name: "Natalia", gender: .female),
            ],
            lines: [
                .init(0, "Pizzería Don Giovanni, ¿me da su número de teléfono, por favor?", "Don Giovanni Pizzeria, may I have your phone number, please?"),
                .init(1, "Sí, es cinco, cinco, dos, ocho, cuatro, uno, siete, nueve, cero, tres.", "Yes, it's five, five, two, eight, four, one, seven, nine, zero, three."),
                .init(0, "Gracias. ¿Qué le vamos a llevar?", "Thank you. What are we bringing you?"),
                .init(1, "Una pizza grande, mitad hawaiana y mitad pepperoni, con orilla rellena de queso.", "A large pizza, half Hawaiian and half pepperoni, with cheese-stuffed crust."),
                .init(0, "¿Algo más? Tenemos promoción de alitas al dos por uno.", "Anything else? We have a two-for-one deal on wings."),
                .init(1, "Ándele, agréguele unas alitas BBQ. ¿Cuánto tardan en llegar?", "Sure, add some BBQ wings. How long does it take to arrive?"),
                .init(0, "Como cuarenta y cinco minutos, porque hay mucha demanda.", "About forty-five minutes, because it's very busy."),
                .init(1, "Está bien. ¿Me podrían traer cambio de quinientos?", "That's fine. Could you bring change for five hundred?"),
                .init(0, "Claro. Su total es de cuatrocientos veinte pesos. ¿Me confirma la dirección?", "Sure. Your total is four hundred twenty pesos. Can you confirm the address?"),
                .init(1, "Calle Durango ciento quince, departamento cuatro, en la colonia Roma.", "115 Durango Street, apartment four, in Colonia Roma."),
                .init(0, "Perfecto, ya va en camino su pedido en un ratito.", "Perfect, your order will be on its way shortly."),
            ]
        ),
        Conversation(
            id: "es-food-street",
            title: "Antojitos en la noche",
            englishTitle: "Late-night street food",
            symbol: "moon.stars",
            level: .intermediate,
            speakers: [
                .init(name: "Leonardo", gender: .male),
                .init(name: "Ximena", gender: .female),
            ],
            lines: [
                .init(0, "Ya tengo hambre. ¿Y si vamos por unos esquites antes de regresar?", "I'm hungry already. What if we go get some esquites before heading back?"),
                .init(1, "¡Va! Hay un puesto en la esquina que siempre tiene fila.", "Okay! There's a stand on the corner that always has a line."),
                .init(0, "Buenas noches, ¿me da dos esquites grandes?", "Good evening, can I have two large esquites?"),
                .init(1, "El mío con todo: mayonesa, queso, limón y chile del que pica.", "Mine with everything: mayo, cheese, lime and the spicy chile."),
                .init(0, "Y el mío sin mayonesa, por favor, nada más con queso y limón.", "And mine without mayo, please, just cheese and lime."),
                .init(1, "Oye, ¿probaste los tamales de rajas de la señora de enfrente?", "Hey, did you try the rajas tamales from the lady across the street?"),
                .init(0, "No, cuando llegué la otra vez ya se le habían acabado.", "No, when I got there last time she had already sold out."),
                .init(1, "Pues hoy todavía tiene. Te invito uno con un atolito de chocolate.", "Well, she still has some today. I'll treat you to one with a chocolate atole."),
                .init(0, "Me convenciste. Aunque mañana empiezo la dieta, ¿eh?", "You convinced me. Although tomorrow I start my diet, okay?"),
                .init(1, "Sí, cómo no. Eso dijiste la semana pasada.", "Yeah, sure. That's what you said last week."),
            ]
        ),
    ]

    /// Sections for the Conversations list, in display order.
    static let spanishSections: [(title: String, conversations: [Conversation])] = [
        ("Food & Restaurants · Intermediate", spanishFood),
    ]
}
