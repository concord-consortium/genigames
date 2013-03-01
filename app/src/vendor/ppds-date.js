/*
    Date class extention
    v1.1.0, 2010-06-03
    Copyright: Paul Philippov, paul@ppds.ws
    Homepage: http://themactep.com/jquery/beats/javascript_date_to_internet_time/
    License: BSD
*/

// Date.toInternetTime(n)
// Converts time to Swatch Internet Time format.
// n - the number of digits after decimal point.
Date.prototype.toInternetTime = function(n)
{
  var BeatInSeconds = 86.4;

  var seconds = this.getUTCSeconds();
  var minutes = this.getUTCMinutes();
  var hours   = this.getUTCHours();
  hours = (hours == 23) ? 0 : hours + 1;

  var BielMeanTime = (hours * 60 + minutes) * 60 + seconds;
  var beats = Math.abs(BielMeanTime / BeatInSeconds).toFixed(parseInt(n));

  var length = (n > 0) ? 1 + n : 0;

  return '@'.concat('000'.concat(beats).slice(beats.length - length));
};

// Date.getDayOfYear()
// Returns the number of days from the beginning of year to the date.
Date.prototype.getDayOfYear = function() {
  var DayInSeconds = 86400000;
  var BeginningOfYear = new Date(this.getFullYear(), 0, 1);
  return Math.ceil((this - BeginningOfYear) / DayInSeconds);
};