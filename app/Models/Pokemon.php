<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Pokemon extends Model
{
    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'pokemon';

    /**
     * The attributes that aren't mass assignable.
     *
     * @var array
     */
    protected $guarded = [];

    /**
     * Indicates if the model should be timestamped.
     *
     * @var bool
     */
    public $timestamps = false;

    /**
     * The attributes that should be cast.
     *
     * @var array
     */
    protected $casts = [
        'name'  => 'array',
        'stats' => 'array',
    ];

    public function types(): BelongsToMany
    {
        return $this->belongsToMany(Type::class);
    }

    public function evolvedFrom(): BelongsToMany
    {
        return $this->belongsToMany(Pokemon::class, 'evolutions', 'to_id', 'from_id')->withPivot(['condition']);
    }

    public function evolvesTo(): BelongsToMany
    {
        return $this->belongsToMany(Pokemon::class, 'evolutions', 'from_id', 'to_id')->withPivot(['condition']);
    }
}
