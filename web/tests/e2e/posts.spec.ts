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

// Creating a post (Step 3) requires an account, same as every other mutation
// in the app — reuses the Step 1 signup/enable/login loop to get one.
async function signUpAndLogIn(page: Page, email: string, password: string) {
  await page.goto('/signup')
  await page.waitForLoadState('networkidle')
  await page.getByLabel('Name').fill('Post Writer')
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

test('picking a book, writing a passage + takeaway + keywords, and publishing', async ({ page }) => {
  const unique = Date.now()
  const email = `e2e-posts-${unique}@example.com`
  const password = 'supersecret1'
  const title = `Composer Test Book ${unique}`
  const author = `Author ${unique}`

  await signUpAndLogIn(page, email, password)

  // Seed a book to write about (Step 2 flow).
  await page.goto('/books/new')
  await page.getByLabel('Title').fill(title)
  await page.getByLabel('Author').fill(author)
  await page.getByRole('button', { name: 'Add book' }).click()
  await expect(page).toHaveURL('/books')

  await page.getByText(title).click()
  await expect(page).toHaveURL(/\/posts\/new\?bookId=/)

  await page.getByLabel('The passage').fill('The forest doesn’t end where the trees stop.')
  await page.getByLabel('What I think about it').fill('This rewired how I pay attention.')
  await page.getByLabel('Add a keyword').fill('attention')
  await page.getByLabel('Add a keyword').press('Enter')

  await page.getByRole('button', { name: 'Publish' }).click()

  await expect(page.getByText('Published!')).toBeVisible()
  await expect(page.getByText(`"${title}" is live.`, { exact: false })).toBeVisible()
})
