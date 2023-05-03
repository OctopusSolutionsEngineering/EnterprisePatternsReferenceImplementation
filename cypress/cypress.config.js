const { defineConfig } = require('cypress')

module.exports = defineConfig({
    e2e: {
        specPattern: "cypress/integration",
        baseUrl: "https://example.org",
        reporter: "mochawesome",
        reporterOptions: {
            "charts": true,
            "overwrite": false,
            "html": true,
            "json": false,
            "reportDir": "."
        },
        supportFile: false,
        retries: 10
    },
});