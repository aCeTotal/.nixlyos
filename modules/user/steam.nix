{ config, pkgs, lib, ... }:

{
  home.activation.setupSteamProton = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    STEAM_DIR="$HOME/.local/share/Steam"
    STEAM_CONFIG_DIR="$STEAM_DIR/config"
    CONFIG_VDF="$STEAM_CONFIG_DIR/config.vdf"

    # Only run if Steam directory exists
    if [ -d "$STEAM_DIR" ]; then
      mkdir -p "$STEAM_CONFIG_DIR"

      # Create config.vdf with Steam Play enabled if it doesn't exist
      if [ ! -f "$CONFIG_VDF" ]; then
        cat > "$CONFIG_VDF" << 'CONFIGEOF'
"InstallConfigStore"
{
	"Software"
	{
		"Valve"
		{
			"Steam"
			{
				"CompatToolMapping"
				{
					"0"
					{
						"name"		"GE-Proton"
						"config"		""
						"priority"		"250"
					}
				}
			}
		}
	}
}
CONFIGEOF
      else
        # If config exists, check if we need to add CompatToolMapping
        if ! ${pkgs.gnugrep}/bin/grep -q '"CompatToolMapping"' "$CONFIG_VDF" 2>/dev/null; then
          # Backup original
          cp "$CONFIG_VDF" "$CONFIG_VDF.bak"

          # Add CompatToolMapping section
          ${pkgs.python3}/bin/python3 << 'PYEOF'
import re
import os

config_path = os.path.expanduser("~/.local/share/Steam/config/config.vdf")

try:
    with open(config_path, 'r') as f:
        content = f.read()

    # Check if CompatToolMapping already exists
    if '"CompatToolMapping"' not in content:
        # Find the Steam section and add CompatToolMapping
        compat_section = '''
				"CompatToolMapping"
				{
					"0"
					{
						"name"		"GE-Proton"
						"config"		""
						"priority"		"250"
					}
				}'''

        # Try to insert before the closing of Steam section
        # Look for pattern like "Steam" { ... } and insert before last }
        pattern = r'("Steam"\s*\{[^}]*?)((\s*}\s*}\s*}\s*)$)'
        if re.search(pattern, content, re.DOTALL):
            content = re.sub(pattern, r'\1' + compat_section + r'\2', content, flags=re.DOTALL)
        else:
            # Fallback: insert before last closing braces
            content = content.rstrip().rstrip('}').rstrip() + compat_section + '\n\t\t}\n\t}\n}\n'

        with open(config_path, 'w') as f:
            f.write(content)
        print("Added CompatToolMapping to config.vdf")
except Exception as e:
    print(f"Note: Could not update config.vdf: {e}")
PYEOF
        fi
      fi
    fi
  '';
}
