
import { test, expect } from '@playwright/test';

test.describe('Golden Thread E2E', () => {
    // Ensure steps run in order (Admin Create -> Spectator Verify)
    test.describe.configure({ mode: 'serial' });

    test('Stage 1: Admin Creates Court', async ({ page }) => {
        // 1. Ensure User exists in Emulator (Handled via a quick attempt or assuming some seed)
        // For the demo emulator, we'll try to login, and if it fails with "user-not-found", we could sign up.
        // But for this project, let's assume the auth provider allows creating account or we use the Rest API.

        await page.goto('/login');
        await page.fill('input[type="email"]', 'admin@padel.com');
        await page.fill('input[type="password"]', 'password123');
        await page.click('button[type="submit"]');

        // If we get an error about user-not-found (check for common error text), 
        // we'd normally handle it. For now, we'll just wait for the dashboard.

        // Verify Dashboard
        await expect(page.getByText('Court Management')).toBeVisible();

        // 2. Create Court
        await page.fill('input[placeholder="e.g. COURT CENTRAL"]', 'Court-Automated');
        await page.click('button:has-text("Add Court")');

        // Verify it appears (case insensitive check for 'Court-Automated' is safer with uppercase UI)
        await expect(page.getByText('Court-Automated', { exact: false })).toBeVisible();

        console.log('Stage 1 Complete: Court Created');
    });

    test('Stage 3: Verify Spectator Update', async ({ page }) => {
        page.on('console', msg => console.log(`BROWSER [${msg.type()}]: ${msg.text()}`));

        console.log('--- Stage 3 Start: Connecting to Homepage ---');
        // Allow more time for Firestore propagation in the emulator environment
        await page.waitForTimeout(5000);

        await page.goto('/');

        // Log the number of courts found as a hint
        const courtHeaders = page.locator('h3');
        const count = await courtHeaders.count();
        console.log(`Found ${count} court headers.`);

        // Use regex for case-insensitive matching
        await expect(page.getByText(/Court-Automated/i)).toBeVisible({ timeout: 15000 });

        console.log('Stage 3: Court found. Clicking Dashboard.');
        // Click "Open Dashboard"
        await page.getByText(/Open Dashboard/i).last().click();

        // Assert idle state first
        await expect(page.getByText(/Waiting for players/i)).toBeVisible();

        console.log('Stage 3 Complete: Idle State Verified');
    });
});
