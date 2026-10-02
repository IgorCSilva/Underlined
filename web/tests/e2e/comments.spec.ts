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
  await page.getByLabel('Name').fill('Comment Tester')
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

test('posting a top-level comment and a reply on a post', async ({ page }) => {
  const unique = Date.now()
  const email = `e2e-comments-${unique}@example.com`
  const password = 'supersecret1'
  const title = `Comment Test Book ${unique}`
  const author = `Author ${unique}`

  await signUpAndLogIn(page, email, password)

  await page.goto('/books/new')
  await page.getByLabel('Title').fill(title)
  await page.getByLabel('Author').fill(author)
  await page.getByRole('button', { name: 'Add book' }).click()
  await expect(page).toHaveURL('/books')

  await page.getByText(title).click()
  await expect(page).toHaveURL(/\/posts\/new\?bookId=/)

  await page.getByLabel('The passage').fill('A passage worth discussing.')
  await page.getByLabel('What I think about it').fill('This made me think.')
  await page.getByRole('button', { name: 'Publish' }).click()
  await expect(page.getByText('Published!')).toBeVisible()

  await page.getByRole('link', { name: 'View post' }).click()
  await expect(page).toHaveURL(/\/posts\/[^/]+$/)

  await expect(page.locator('.post-icon').getByText('💬 0')).toBeVisible()

  await page.locator('.comment-thread-composer .comment-input').fill('Great read!')
  await page.locator('.comment-thread-composer').getByRole('button', { name: 'Post' }).click()

  const comment = page.locator('.comment-item', { hasText: 'Great read!' }).first()
  await expect(comment).toBeVisible()
  await expect(page.locator('.post-icon').getByText('💬 1')).toBeVisible()

  await comment.getByRole('button', { name: 'Reply' }).click()
  await comment.locator('.comment-reply-composer .comment-input').fill('Agreed!')
  await comment.locator('.comment-reply-composer').getByRole('button', { name: 'Post' }).click()

  const reply = comment.locator('.comment-replies .comment-item', { hasText: 'Agreed!' })
  await expect(reply).toBeVisible()
  await expect(page.locator('.post-icon').getByText('💬 2')).toBeVisible()

  await page.reload()
  await page.waitForLoadState('networkidle')
  await expect(page.locator('.comment-item', { hasText: 'Great read!' })).toBeVisible()
  await expect(page.locator('.comment-item', { hasText: 'Agreed!' })).toBeVisible()
  await expect(page.locator('.post-icon').getByText('💬 2')).toBeVisible()
})
