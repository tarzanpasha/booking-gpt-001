<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TimetableDate extends Model
{
    protected $table = 'timetable_dates';
    protected $fillable = ['timetable_id','date','start','end','breaks'];
    protected $casts = ['breaks'=>'array', 'date'=>'date:Y-m-d'];

    public function timetable() { return $this->belongsTo(Timetable::class); }
}
