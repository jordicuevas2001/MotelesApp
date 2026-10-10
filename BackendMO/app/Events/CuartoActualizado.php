<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class CuartoActualizado implements ShouldBroadcastNow
{
    use Dispatchable, SerializesModels;

    public int $motelId;
    public int $cuartoId;
    public string $accion;

    public function __construct(
        int $motelId,
        int $cuartoId,
        string $accion
    ) {
        $this->motelId = $motelId;
        $this->cuartoId = $cuartoId;
        $this->accion = $accion;
    }

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel(
                'moteles.' . $this->motelId
            ),
        ];
    }

    public function broadcastAs(): string
    {
        return 'cuarto.actualizado';
    }

    public function broadcastWith(): array
    {
        return [
            'motel_id' => $this->motelId,
            'cuarto_id' => $this->cuartoId,
            'accion' => $this->accion,
        ];
    }
}
