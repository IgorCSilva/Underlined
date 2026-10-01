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

// Adding a book (Step 2) requires an account, same as every other mutation
// in the app — reuses the Step 1 signup/enable/login loop to get one.
async function signUpAndLogIn(page: Page, email: string, password: string) {
  await page.goto('/signup')
  await page.waitForLoadState('networkidle')
  await page.getByLabel('Name').fill('Book Adder')
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

test('searching finds nothing for a nonsense query, then adding a book makes it searchable', async ({ page }) => {
  const unique = Date.now()
  const email = `e2e-books-${unique}@example.com`
  const password = 'supersecret1'
  const title = `Nonsense Query Book ${unique}`
  const author = `Author ${unique}`

  await signUpAndLogIn(page, email, password)

  await page.goto('/books')
  await page.waitForLoadState('networkidle')
  await page.getByLabel('Search books').fill(`nonexistent-${unique}`)
  await expect(page.getByText(title)).toHaveCount(0)

  await page.getByRole('link', { name: /Add a book/ }).click()
  await expect(page).toHaveURL('/books/new')
  await page.getByLabel('Title').fill(title)
  await page.getByLabel('Author').fill(author)
  await page.getByRole('button', { name: 'Add book' }).click()

  await expect(page).toHaveURL('/books')
  await expect(page.getByText(title)).toBeVisible()

  await page.getByLabel('Search books').fill(author)
  await expect(page.getByText(title)).toBeVisible()
})
