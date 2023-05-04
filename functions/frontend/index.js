const fs = require('fs');
const path = require('path');

module.exports = function (context, req) {
    context.log('HTTP trigger function processed a request.');

    if (req.query.name || (req.body && req.body.name)) {
        context.res = {
            // status: 200, /* Defaults to 200 */
            body: "Hey " + (req.query.name || req.body.name)
        };
        context.done();

    } else {

        // Read an HTML file in the directory and return the contents
        fs.readFile(path.resolve(__dirname, 'index.html'), 'UTF-8', (err, htmlContent) => {
            context.res = {
                headers: {"Content-Type": "text/html"},
                body: htmlContent
            };

            context.done();
        });

    }
};