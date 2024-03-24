import type { Config } from "tailwindcss";
import type { PluginAPI } from "tailwindcss/types/config";

export default {
  content: [
    "./src/**/*.{js,elm,ts,css,html}",
    "./.elm-land/**/*.{js,elm,ts,css,html}",
  ],
  darkMode: "media", // or 'class'
  theme: {
    fontFamily: {
      sans: [
        "Work Sans",
        "ui-sans-serif",
        "system-ui",
        "sans-serif",
        '"Apple Color Emoji"',
        '"Segoe UI Emoji"',
        '"Segoe UI Symbol"',
        '"Noto Color Emoji"',
      ],
    },
  },
  plugins: [
    require("@tailwindcss/typography"),
    require("@tailwindcss/forms"),
    require("@tailwindcss/aspect-ratio"),
    require("@tailwindcss/container-queries"),
    dynamicGridPlugin,
  ],
} satisfies Config;

/**
 * Simplifies defining dynamic grid layouts where the column widths should
 * grow/shrink to fill the grid container. The number of columns will change based
 * on how many can fit in the container based on the column min-width.
 *
 * Source: <https://stackoverflow.com/a/69154193/8644590>
 */
function dynamicGridPlugin({
  addUtilities,
  theme,
  matchUtilities,
}: PluginAPI): void {
  const name = "dg";

  const minCols = "--min-cols";
  /** @default 1 */
  const varMinCols = `var(${minCols},1)`;
  matchUtilities(
    {
      [`${name}-min-cols`]: (value) => ({
        [minCols]: value,
      }),
    },
    {
      values: {
        1: "1",
        2: "2",
        3: "3",
        4: "4",
        5: "5",
        6: "6",
      },
    }
  );

  const maxCols = "--max-cols";
  /** @default var(--min-cols) */
  const varMaxCols = `var(${maxCols},${varMinCols})`;
  matchUtilities(
    {
      [`${name}-max-cols`]: (value) => ({
        [maxCols]: value,
      }),
    },
    {
      values: {
        1: "1",
        2: "2",
        3: "3",
        4: "4",
        5: "5",
        6: "6",
        7: "7",
        8: "8",
      },
    }
  );

  const colMinWidth = "--col-min-width";
  /** @default 2rem */
  const varColsMinWidth = `var(${colMinWidth},2rem)`;
  matchUtilities(
    {
      [`${name}-col-min-w`]: (value) => ({
        [colMinWidth]: value,
      }),
    },
    {
      values: theme("spacing"),
    }
  );

  const gridColumnGap = "--grid-column-gap";
  /** @default 1rem */
  const varGridColumnGap = `var(${gridColumnGap},1rem)`;
  matchUtilities(
    {
      [`${name}-col-gap`]: (value) => ({
        [gridColumnGap]: value,
      }),
    },
    {
      values: theme("spacing"),
    }
  );

  const gridRowGap = "--grid-row-gap";
  /** @default var(--grid-column-gap) */
  const varGridRowGap = `var(${gridRowGap},${varGridColumnGap})`;
  matchUtilities(
    {
      [`${name}-row-gap`]: (value) => ({
        [gridRowGap]: value,
      }),
    },
    {
      values: theme("spacing"),
    }
  );

  addUtilities({
    [`.${name}`]: {
      gridTemplateColumns: `repeat(auto-fit, minmax(min((100%/${varMinCols} - ${varGridColumnGap}*(${varMinCols} - 1)/${varMinCols}), max(${varColsMinWidth}, (100%/${varMaxCols} - ${varGridColumnGap}*(${varMaxCols} - 1)/${varMaxCols}))), 1fr))`,
      gridColumnGap: `${varGridColumnGap}`,
      gridRowGap: `${varGridRowGap}`,
      display: "grid",
    },
  });
}
