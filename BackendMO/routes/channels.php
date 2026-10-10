<?php

use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('moteles.{motelId}', function ($user, $motelId) {

    // El administrador puede ver cualquie  motel
    if ($user->rol === 'admin') {
        return true;
    }

    // Un usuario normal solo puede ver su propio motel
    return (int) $user->motel_id === (int) $motelId;
});
