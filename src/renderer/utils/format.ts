export function formatMinutes(m: number): string {
  const hrs = Math.floor(m / 60)
  const mins = Math.round(m % 60)
  return hrs > 0 ? `${hrs}h ${mins}m` : `${mins}m`
}
