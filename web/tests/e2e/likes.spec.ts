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

async function signUpAndLogIn(page: Page, email: string, password: string) {
  await page.goto('/signup')
  await page.waitForLoadState('networkidle')
  await page.getByLabel('Name').fill('Like Tester')
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

test('liking and unliking a post updates the heart and count', async ({ page }) => {
  const unique = Date.now()
  const email = `e2e-like-${unique}@example.com`
  const password = 'supersecret1'
  const title = `Like Test Book ${unique}`
  const author = `Author ${unique}`
  const passage = `A passage worth liking ${unique}.`
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
  await page.getByRole('button', { name: 'Publish' }).click()
  await expect(page.getByText('Published!')).toBeVisible()

  await page.getByRole('link', { name: 'View post' }).click()
  await expect(page).toHaveURL(/\/posts\/[^/]+$/)

  const likeButton = page.locator('.like-button')
  await expect(likeButton.locator('.like-icon')).toHaveText('♡')
  await expect(likeButton.locator('.like-count')).toHaveText('0')

  await likeButton.click()
  await expect(likeButton.locator('.like-icon')).toHaveText('♥')
  await expect(likeButton.locator('.like-count')).toHaveText('1')

  await page.reload()
  await page.waitForLoadState('networkidle')
  await expect(page.locator('.like-button .like-icon')).toHaveText('♥')
  await expect(page.locator('.like-button .like-count')).toHaveText('1')

  await page.locator('.like-button').click()
  await expect(page.locator('.like-button .like-icon')).toHaveText('♡')
  await expect(page.locator('.like-button .like-count')).toHaveText('0')
})
