import { execSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import path from 'node:path'
import { expect, test } from '@playwright/test'

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..')

// Registration no longer sends a real confirmation email (see
// deploy/specifications.md) — new accounts sit disabled until the
// responsible party flips `enabled` in the database by hand. This stands in
// for that manual step so the rest of the flow can still be exercised here.
function enableAccount(email: string) {
  execSync(
    `docker compose exec -T postgres psql -U underlined -d underlined_dev -c "UPDATE users SET enabled = true WHERE email = '${email}';"`,
    { cwd: repoRoot },
  )
}

// Exercises the full Step 1 loop against the real docker-compose stack:
// sign up -> see the pending-confirmation message -> (manually enable) -> log
// in -> edit the profile -> log out -> log back in with "remember me" and see
// the updated profile again.
test('sign up, get enabled, edit profile, log out, and log back in', async ({ page }) => {
  const unique = Date.now()
  const email = `e2e-${unique}@example.com`
  const password = 'supersecret1'

  await page.goto('/signup')
  // Nuxt's dev server compiles each route's client chunk on first visit, so
  // interacting immediately after `goto` can race hydration (the click lands
  // before Vue's `@submit.prevent` handler is attached, and the browser falls
  // back to a native form GET). Waiting for the network to settle avoids that.
  await page.waitForLoadState('networkidle')
  await page.getByLabel('Name').fill('E2E Reader')
  await page.getByLabel('Email').fill(email)
  await page.getByLabel('Password').fill(password)
  await page.getByRole('button', { name: 'Sign up' }).click()

  await expect(page.getByText(/will send you an email to confirm/)).toBeVisible()

  enableAccount(email)

  await page.getByRole('link', { name: 'Back to log in' }).click()
  await expect(page).toHaveURL('/login')
  await page.getByLabel('Email').fill(email)
  await page.getByLabel('Password').fill(password)
  await page.getByRole('button', { name: 'Log in' }).click()

  await expect(page).toHaveURL('/profile')
  await expect(page.getByRole('heading', { name: 'E2E Reader' })).toBeVisible()

  await page.getByRole('link', { name: 'Edit profile' }).click()
  await expect(page).toHaveURL('/profile/edit')
  await page.getByLabel('Bio').fill('I read things and write about them.')
  await page.getByRole('button', { name: 'Save changes' }).click()

  await expect(page).toHaveURL('/profile')
  await expect(page.getByText('I read things and write about them.')).toBeVisible()

  await page.evaluate(async () => {
    await fetch('http://localhost:4000/api/auth/logout', { method: 'DELETE', credentials: 'include' })
  })
  await page.goto('/profile')
  await page.waitForLoadState('networkidle')
  await expect(page).toHaveURL(/\/login/)

  await page.getByLabel('Email').fill(email)
  await page.getByLabel('Password').fill(password)
  await page.getByLabel('Remember me').check()
  await page.getByRole('button', { name: 'Log in' }).click()

  await expect(page).toHaveURL('/profile')
  await expect(page.getByText('I read things and write about them.')).toBeVisible()
})

test('logging in before the account is enabled is rejected', async ({ page }) => {
  const unique = Date.now()
  const email = `e2e-pending-${unique}@example.com`
  const password = 'supersecret1'

  await page.goto('/signup')
  await page.waitForLoadState('networkidle')
  await page.getByLabel('Name').fill('Pending Reader')
  await page.getByLabel('Email').fill(email)
  await page.getByLabel('Password').fill(password)
  await page.getByRole('button', { name: 'Sign up' }).click()
  await expect(page.getByText(/will send you an email to confirm/)).toBeVisible()

  await page.getByRole('link', { name: 'Back to log in' }).click()
  await page.getByLabel('Email').fill(email)
  await page.getByLabel('Password').fill(password)
  await page.getByRole('button', { name: 'Log in' }).click()

  await expect(page.getByText('account pending confirmation')).toBeVisible()
  await expect(page).toHaveURL('/login')
})
