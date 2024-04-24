-- PipeWire's S24LE default audio format is broken in the kernel driver
table.insert(alsa_monitor.rules,
  {
    matches = {
      {
        { "node.name", "matches", "alsa_output.*.HiFi*__sink" },
      },
      {
        { "node.name", "matches", "alsa_input.*.HiFi*__source" },
      },
    },
    apply_properties = {
      ["audio.format"]           = "S16LE",
      ["audio.rate"]             = 48000,
      ["api.alsa.period-size"]   = 65536,
      ["api.alsa.period-num"]    = 8,
      ["api.alsa.headroom"]      = 512,
    },
  }
)

