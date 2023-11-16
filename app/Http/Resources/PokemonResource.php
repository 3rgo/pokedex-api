<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PokemonResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id'          => $this->id,
            'generation'  => $this->generation,
            'name'        => $this->name,
            'image'       => $this->image,
            'image_shiny' => $this->image_shiny,
            'height'      => $this->height,
            'weight'      => $this->weight,
            'stats'       => $this->stats,
            'types'       => $this->types->pluck('id'),
            'evolvedFrom' => $this->evolvedFrom->pluck('pivot.condition', 'id'),
            'evolvesTo'   => $this->evolvesTo->pluck('pivot.condition', 'id'),
        ];
    }
}
