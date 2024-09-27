#!/bin/bash

for i in "$@"
do
case $i in
    -a|--all) GENERATE_ALL="1";;
    -d|--drc) GENERATE_DRC="1";;
    -e|--erc) GENERATE_ERC="1";;
    -g|--gerber) GENERATE_GERBERS="1";;
    -dr|--drill) GENERATE_DRILL="1";;
    -s|--step) GENERATE_STEP="1";;
    -sp|--sch-pdf) GENERATE_SCH_PDF="1";;
    -pp|--pcb-pdf) GENERATE_PCB_PDF="1";;
    -b|--bom) GENERATE_BOM="1";;
    -h|--help)
        echo "Usage: generate_kicad_outputs.sh [--help] [--all] [--drc] [--gerber] [--drill] [--step] [--sch-pdf] [--pcb-pdf] [--bom]"
        echo ""
        echo "Options:"
        echo "  -a|--all        generate all outputs"
        echo "  -d|--drc        generate DRC reports" 
        echo "  -e|--erc        generate ERC reports"
        echo "  -g|--gerber     generate gerber files" 
        echo "  -dr|--drill     generate drill files"
        echo "  -s|--step       generate STEP file"
        echo "  -sp|--sch-pdf   generate schematic PDF"
        echo "  -pp|--pcb-pdf   generate PCB PDF"
        echo "  -b|--bom        generate bill of materials csv"
        echo "  -h,--help       print this help"
        exit;;
esac
done

main()
{
    kicad-cli --version
    
    # set up output directories
    ROOT_DIR=$(git rev-parse --show-toplevel)
    pushd "$ROOT_DIR"

    SOURCE_DIR=$ROOT_DIR/pcb
    OUTPUT_ROOT_DIR=$ROOT_DIR/output
    GERBER_DIR=$OUTPUT_ROOT_DIR/gerbers
    DRC_DIR=$OUTPUT_ROOT_DIR/drc
    ERC_DIR=$OUTPUT_ROOT_DIR/erc
    DRILL_DIR=$OUTPUT_ROOT_DIR/drill
    STEP_DIR=$OUTPUT_ROOT_DIR/step
    PDF_DIR=$OUTPUT_ROOT_DIR/pdf
    BOM_DIR=$OUTPUT_ROOT_DIR/bom

    # generate DRC
    if [ "$GENERATE_ALL" = "1" ] || [ "$GENERATE_DRC" = "1" ]; then 
        echo "Generating DRC outputs";
        if [ ! -d "$DRC_DIR" ]; then mkdir -p $DRC_DIR; fi
        kicad-cli pcb drc --output="$DRC_DIR"/ghost-bot-drc.json --format=json --all-track-errors --schematic-parity --units=mm --severity-all --exit-code-violations "$SOURCE_DIR"/ghost-bot.kicad_pcb
        kicad-cli pcb drc --output="$DRC_DIR"/ghost-bot-drc.rpt --format=report --all-track-errors --schematic-parity --units=mm --severity-all --exit-code-violations "$SOURCE_DIR"/ghost-bot.kicad_pcb
    fi

    if [ "$GENERATE_ALL" = "1" ] || [ "$GENERATE_ERC" = "1" ]; then
        echo "Generating DRC outputs";
        if [ ! -d "$ERC_DIR" ]; then mkdir -p $ERC_DIR; fi
        kicad-cli sch erc --output="$ERC_DIR"/ghost-bot-erc.json --format=json --units=mm --severity-all --exit-code-violations "$SOURCE_DIR"/ghost-bot.kicad_sch
        kicad-cli sch erc --output="$ERC_DIR"/ghost-bot-erc.rpt --format=report --units=mm --severity-all --exit-code-violations "$SOURCE_DIR"/ghost-bot.kicad_sch
    fi

    # generate gerber files for jlc-pcb, see # https://jlcpcb.com/help/article/362-how-to-generate-gerber-and-drill-files-in-kicad-7 for options
    if [ "$GENERATE_ALL" = "1" ] || [ "$GENERATE_GERBERS" = "1" ]; then 
        echo "Generating gerber outputs";
        if [ ! -d "$GERBER_DIR" ]; then mkdir -p $GERBER_DIR; fi
        kicad-cli pcb export gerbers --output="$GERBER_DIR"/ --layers="F.Cu,F.Paste,F.Silkscreen,F.Mask,B.Cu,B.Paste,B.Silkscreen,B.Mask,Edge.Cuts" --subtract-soldermask --exclude-value --no-x2 --no-netlist "$SOURCE_DIR"/ghost-bot.kicad_pcb
    fi

    # generate drill file for jlc-pcb
    if [ "$GENERATE_ALL" = "1" ] || [ "$GENERATE_DRILL" = "1" ]; then 
        echo "Generating drill outputs";
        if [ ! -d "$DRILL_DIR" ]; then mkdir -p $DRILL_DIR; fi
        kicad-cli pcb export drill --output="$DRILL_DIR"/ --format=excellon --drill-origin=absolute --excellon-zeros-format=decimal --excellon-units=mm --excellon-oval-format=alternate --generate-map --map-format=gerberx2 "$SOURCE_DIR"/ghost-bot.kicad_pcb
    fi

    # generate step file
    if [ "$GENERATE_ALL" = "1" ] || [ "$GENERATE_STEP" = "1" ]; then 
        echo "Generating step outputs";
        if [ ! -d "$STEP_DIR" ]; then mkdir -p $STEP_DIR; fi
        kicad-cli pcb export step --drill-origin --subst-models --force --min-distance=0.01mm --output="$STEP_DIR"/ghost-bot.step "$SOURCE_DIR"/ghost-bot.kicad_pcb    
    fi

    # generate pcb pdf
    if [ "$GENERATE_ALL" = "1" ] || [ "$GENERATE_PCB_PDF" = "1" ]; then 
        echo "Generating pcb pdf outputs";
        if [ ! -d "$PDF_DIR" ]; then mkdir -p $PDF_DIR; fi
        kicad-cli pcb export pdf --output="$PDF_DIR"/ghost-bot-pcb.pdf --include-border-title --layers="B.Cu,B.Paste,B.Silkscreen,B.Mask,F.Cu,F.Paste,F.Silkscreen,F.Mask,Edge.Cuts" "$SOURCE_DIR"/ghost-bot.kicad_pcb
    fi

    # generate sch pdf
    if [ "$GENERATE_ALL" = "1" ] || [ "$GENERATE_SCH_PDF" = "1" ]; then 
        echo "Generating sch pdf outputs";
        if [ ! -d "$PDF_DIR" ]; then mkdir -p $PDF_DIR; fi
        kicad-cli sch export pdf --output="$PDF_DIR"/ghost-bot-schematic.pdf "$SOURCE_DIR"/ghost-bot.kicad_sch
    fi

    # generate bom
    if [ "$GENERATE_ALL" = "1" ] || [ "$GENERATE_BOM" = "1" ]; then 
        echo "Generating BOM outputs";
        if [ ! -d "$BOM_DIR" ]; then mkdir -p $BOM_DIR; fi
        kicad-cli sch export bom --output="$BOM_DIR"/ghost-bot-bom.csv --group-by="Supplier Part Number" --format-preset=CSV --fields="Reference,Value,\${QUANTITY},\${DNP},Supplier Part Number,Manufacturer Part Number,Supplier " --field-delimiter="," "$SOURCE_DIR"/ghost-bot.kicad_sch
    fi
}
main