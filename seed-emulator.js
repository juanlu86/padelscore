const projectId = "padelscore-watch-1e0d3";
const documentPath = "matches/test-match";
const url = `http://127.0.0.1:8080/v1/projects/${projectId}/databases/(default)/documents/${documentPath}`;

const matchData = {
    fields: {
        team1: { stringValue: "Galan/Lebron" },
        team2: { stringValue: "Coello/Tapia" },
        score: {
            mapValue: {
                fields: {
                    team1: { stringValue: "30" },
                    team2: { stringValue: "15" }
                }
            }
        },
        status: { stringValue: "live" }
    }
};

async function seed() {
    console.log(`Seeding data to: ${url}`);
    try {
        const response = await fetch(`${url}?currentDocument.exists=false`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(matchData)
        });

        if (response.ok) {
            console.log("✅ Success! Document created in emulator.");
        } else {
            // If it already exists, just update it
            const updateResponse = await fetch(url, {
                method: 'PATCH',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(matchData)
            });
            if (updateResponse.ok) {
                console.log("✅ Success! Document updated in emulator.");
            } else {
                console.error("❌ Failed to seed emulator:", await updateResponse.text());
            }
        }
    } catch (err) {
        console.error("❌ Error connecting to emulator:", err.message);
        console.log("\nMake sure your emulators are running with 'firebase emulators:start'");
    }
}

seed();
