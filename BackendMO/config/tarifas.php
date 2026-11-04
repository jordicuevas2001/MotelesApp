
<?php

return [

    'moteles' => [

        1 => [ // El Faraón

            'minutos_gratis' => 5,

            'franjas' => [
                [
                    'horas' => 70 / 60,
                    'precio' => 200,
                ],
                [
                    'horas' => 130 / 60,
                    'precio' => 270,
                ],
            ],

            'precio_hora_extra' => 100,
        ],

        2 => [ // La Curva

            'minutos_gratis' => 5,

            'franjas' => [
                [
                    'horas' => 70 / 60,
                    'precio' => 170,
                ],
                [
                    'horas' => 130 / 60,
                    'precio' => 210,
                ],
            ],

            'precio_hora_extra' => 80,
        ],

    ],

];
