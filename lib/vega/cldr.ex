defmodule Vega.Cldr do
  use Cldr,
      locales: ["en", "de"],
      default_locale: "en",
      providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime]

end