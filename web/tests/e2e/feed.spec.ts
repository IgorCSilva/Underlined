import { execSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import path from 'node:path'
import { expect, test, type Page } from '@playwright/test'

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..')

function enableAccount(email: string) {
  execSync(
    `docker compose exec -T postgres psql -U underlined -d underlined_dev -c "UPDATE users SET enabled = true WHERE email = '${email}';"`,
    { cwd: repoRoot },
  )
}

// Browsing the feed (Step 4) needs a published post to look at, so this
// reuses the Step 1 signup/enable/login loop and the Step 3 publish flow.
async function signUpAndLogIn(page: Page, email: string, password: string) {
  await page.goto('/signup')
  await page.waitForLoadState('networkidle')
  await page.getByLabel('Name').fill('Feed Reader')
  await page.getByLabel('Email').fill(email)
  await page.getByLabel('Password').fill(password)
  await page.getByRole('button', { name: 'Sign up' }).click()
  await expect(page.getByText(/will send you an email to confirm/)).toBeVisible()

  enableAccount(email)

  await page.getByRole('link', { name: 'Back to log in' }).click()
  await page.getByLabel('Email').fill(email)
  await page.getByLabel('Password').fill(password)
  await page.getByRole('button', { name: 'Log in' }).click()
  await expect(page).toHaveURL('/profile')
}

test('a published post appears in the feed and opens its own detail page', async ({ page }) => {
  const unique = Date.now()
  const email = `e2e-feed-${unique}@example.com`
  const password = 'supersecret1'
  const title = `Feed Test Book ${unique}`
  const author = `Author ${unique}`
  const passage = `A passage worth underlining ${unique}.`
  const thinking = `This made me think about things ${unique}.`

  await signUpAndLogIn(page, email, password)

  await page.goto('/books/new')
  await page.getByLabel('Title').fill(title)
  await page.getByLabel('Author').fill(author)
  await page.getByRole('button', { name: 'Add book' }).click()
  await expect(page).toHaveURL('/books')

  await page.getByText(title).click()
  await expect(page).toHaveURL(/\/posts\/new\?bookId=/)

  await page.getByLabel('The passage').fill(passage)
  await page.getByLabel('What I think about it').fill(thinking)
  await page.getByLabel('Add a keyword').fill('attention')
  await page.getByLabel('Add a keyword').press('Enter')
  await page.getByRole('button', { name: 'Publish' }).click()
  await expect(page.getByText('Published!')).toBeVisible()

  await page.goto('/feed')
  await expect(page.getByText(passage)).toBeVisible()
  await expect(page.getByText(title)).toBeVisible()

  await page.getByText(passage).click()
  await expect(page).toHaveURL(/\/posts\/[^/]+$/)
  await expect(page.getByText(passage)).toBeVisible()
  await expect(page.getByText(thinking)).toBeVisible()
  await expect(page.getByText('attention')).toBeVisible()
})
