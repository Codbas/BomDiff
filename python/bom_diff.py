import pandas as pd
import re
from io import StringIO
from datetime import datetime

qty_col_names = ["BOM Quantity", "BoM Quantity per Assembly"]
item_col_names = ["Item", "Component Name"]
bom1_qty_col = ""
bom1_item_col = ""
bom2_qty_col = ""
bom2_item_col = ""

bom1_filename = "B.5.csv"
bom2_filename = "B.5.0.1.csv"

# readcsv of first BOM
try:
    bom1 = pd.read_csv(bom1_filename)
except FileNotFoundError:
    print(f"Error: '{bom1_filename}' not found")
    exit()
except pd.errors.EmptyDataError:
    print(f"Error: '{bom1_filename}' contains no data")
    exit()
except pd.errors.ParserError:
    print(f"Error: '{bom1_filename}' contains malformed data")
    exit()

# readcsv of second BOM
try:
    bom1 = pd.read_csv(bom2_filename)
except FileNotFoundError:
    print(f"Error: '{bom2_filename}' not found")
    exit()
except pd.errors.EmptyDataError:
    print(f"Error: '{bom2_filename}' contains no data")
    exit()
except pd.errors.ParserError:
    print(f"Error: '{bom2_filename}' contains malformed data")
    exit()

# find qty and item column names for first BOM

# find qty and item columns for second BOM


# create diff dataframe
diff_df = pd.DataFrame()

# iterate through all lines on first bom

    # if item found
        # if qty is the same
            # remove item from second bom
            # continue

        # if qty is different
            # add diff_df: qty of first BOM minus second BOM
            # remove item from second bom
            # continue


# if second bom is not empty
    # append second BOM to diff_df


# export diff_df to bom_diff.csv
