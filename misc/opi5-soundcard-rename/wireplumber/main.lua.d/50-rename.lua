rule_es8388 = {
    matches = {
        {
            { "device.name", "equals", "alsa_card.platform-es8388-sound" },
        },
    },
    apply_properties = {
        ["device.description"] = "ES8388 Audio",
    },
}

rule_dp0 = {
    matches = {
        {
            { "device.name", "equals", "alsa_card.platform-dp0-sound" },
        },
    },
    apply_properties = {
        ["device.description"] = "DP0 Audio",
    },
}

rule_hdmi0 = {
    matches = {
        {
            { "device.name", "equals", "alsa_card.platform-hdmi0-sound" },
        },
    },
    apply_properties = {
        ["device.description"] = "HDMI0 Audio",
    },
}

table.insert(alsa_monitor.rules,rule_es8388)
table.insert(alsa_monitor.rules,rule_dp0)
table.insert(alsa_monitor.rules,rule_hdmi0)
