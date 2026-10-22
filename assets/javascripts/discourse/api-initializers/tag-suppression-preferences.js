import { apiInitializer } from "discourse/lib/api";

export default apiInitializer((api) => {
  api.registerValueTransformer(
    "preferences-save-attributes",
    ({ value, context }) => {
      if (context.page === "interface" && !value.includes("custom_fields")) {
        return [...value, "custom_fields"];
      }
      return value;
    }
  );
});
